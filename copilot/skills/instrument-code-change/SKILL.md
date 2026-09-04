---
name: instrument-code-change
description: >
  Use this skill whenever the user asks to add, review, fix, or improve logging,
  log levels, metrics, traces, spans, telemetry, monitoring, instrumentation, or
  observability, asks to instrument a service, endpoint, handler, job, worker, or
  consumer, asks what to measure or what a dashboard or alert should cover, asks
  about swallowed errors or production error reporting, or is diagnosing a
  production failure with too little signal (for example "add logging here",
  "instrument this", "what should I be measuring", "there's nothing in the logs",
  "this failed in prod and I have no idea why"). Also use it when a change adds a
  service boundary, background job, queue consumer, or outbound dependency to
  production code, since those are where instrumentation gets decided. It picks
  the smallest signal that answers a real operational question, follows the
  repository's existing telemetry over any better default, and keeps secrets,
  PII, and unbounded cardinality out of telemetry.
---

# Instrumenting a Code Change

Whether someone can answer "is it broken, where, and why" is decided when the
code is written, not when the pager goes off.

Two failure modes, and both are common:

- **Nothing.** A handler that fails silently, a `catch` with an empty body, an
  error logged at `info` with the stack thrown away, a service that logs its own
  startup and then goes quiet through the entire outage.
- **Everything.** A log line per row in a batch, a user id as a metric label, a
  request body in a span attribute. This costs real money, buries the signal,
  degrades a metrics backend, and puts data in a retained store that should never
  have left the process.

The rule is not "add telemetry". It is: name the operational question, add the
smallest signal that answers it, and state the decision when the answer is that
nothing is needed.

## Read the repository first

Every default in this document loses to what the repository already does.

| Find | How |
| --- | --- |
| The logger | `package.json`, `go.mod`, `Gemfile` for `pino`, `winston`, `zap`, `zerolog`, `logrus`, `log/slog`, `semantic_logger`, `lograge`. Read how the nearest handler calls it. |
| The telemetry SDK, and **which auto-instrumentations are registered** | `@opentelemetry/*`, `go.opentelemetry.io/otel`, `opentelemetry-sdk`, or a vendor SDK such as `dd-trace`, `@sentry/*`, `newrelic`. This decides how much already exists. |
| The error reporter | `Sentry.captureException`, `Rails.error.report`, Bugsnag, Honeybadger, or a house wrapper. |
| The existing conventions | Grep twenty existing log calls for field names, level usage, metric prefixes, and span names. If the codebase writes `request_id`, do not add `requestId`. If it uses `warn` where this document says `info`, follow the codebase. |
| Whether telemetry is tested | Search tests for a log spy, an in-memory span exporter, or a metrics reader. If the repo asserts on telemetry, your change adds assertions too. |
| Where telemetry actually goes | Structured stdout scraped by an agent, a sidecar collector, a vendor endpoint. A signal nobody exports is a signal nobody has. |

**A new telemetry dependency is a last resort and needs approval.** A logging
library, metrics client, tracing SDK, or error reporter is a production
dependency, a config surface, and a recurring cost. If the repository has no
instrumentation at all, that is a decision someone made. Propose the smallest
thing that fits the deployment target, and ask.

## Decide what to instrument

Boundaries are where instrumentation is *considered*, not where it is owed. Work
through them in this order:

1. **What already exists and is exported?** Framework and library
   auto-instrumentation covers many of these boundaries, but which signals it
   emits varies by package, version, and configuration. Read the registration and
   confirm what actually arrives rather than assuming.
2. **What question is still unanswered?** Name it concretely: "which downstream
   call is slow", "how often does this fall back to the cache", "why did this
   job stop finishing".
3. **What is the smallest signal that answers it?** Add that one thing.
4. **If nothing is unanswered, add nothing,** and say so.

### The boundaries worth checking

Inbound requests and RPCs. Outbound HTTP and RPC calls. Database and cache
access. Queue publish and consume. Scheduled and background jobs. Anything
crossing a process, network, or thread edge. State transitions with business
meaning: order shipped, subscription cancelled, tenant provisioned.

### Pick one new signal, not one of each

| Signal | Answers | Cost |
| --- | --- | --- |
| Metric | How often, how slow, how many, trending over time | A time series per label combination, held for the retention period |
| Span | Where inside one request the time went and what it touched | Per request, usually sampled |
| Log | What specifically happened to this one thing | Per event, at every hop: emit, ship, index, store, retain |

Most changes need one. Some need two. Needing all three for one operation is
rare and should be argued for, not assumed.

Marking a span or a metric that **already exists** is not adding a signal. An
error status on the span you own and an `error.type` on an existing histogram are
cheap state markers, and they do not count against this rule.

### Where instrumentation is not worth it

- **Pure functions and internal helpers.** No failure mode the caller cannot see,
  and a test finds their bugs faster than a log line will.
- **Anything auto-instrumentation already covers.** A hand-written duplicate
  doubles the cost and makes the trace harder to read. Add an attribute to the
  existing span instead of nesting a new one.
- **Per-item work in a loop.** Instrument the batch. If the count is bounded by
  input rather than by code, it is not a log site.
- **Routine control flow.** Entering a function, taking a branch, passing a
  validation. "Reached here" is a debugger's job.
- **An internal refactor that changes no boundary.** Usually nothing at all.

**Report the decision either way.** One line: "no new telemetry; the existing
request span and error metric already answer this". That is the difference
between a considered decision and a skipped step.

## Logs

### One static message, everything else in fields

The message identifies the kind of event and must be identical on every call, so
it can be grouped, filtered, counted, and alerted on. Everything that varies is a
field.

```ts
// ❌ unique per call: cannot be grouped, filtered, or counted, and leaks an email
logger.info(`Order ${order.id} shipped to ${user.email} in ${ms}ms`);

// ✅ stable message, variable data in fields, identifier instead of contact data
logger.info({ orderId: order.id, userId: user.id, durationMs: ms }, "order shipped");
```

Pino takes the merging object first and the message second.

```go
// ❌
slog.Info(fmt.Sprintf("order %s shipped in %dms", order.ID, elapsed.Milliseconds()))

// ✅ LogAttrs is the lower-allocation form; it takes Attrs rather than loose pairs
slog.LogAttrs(ctx, slog.LevelInfo, "order shipped",
    slog.String("order_id", order.ID),
    slog.Duration("duration", elapsed),
)
```

```ruby
# ❌
Rails.logger.info "Order #{order.id} shipped in #{ms}ms"

# ✅ needs a structured formatter, which Rails does not ship in core
Rails.logger.info(message: "order shipped", order_id: order.id, duration_ms: ms)
```

Rails has no core JSON log formatter. Structured output depends on `lograge`,
`semantic_logger`, or a formatter the app configures, so check what is set up
before assuming a hash serializes. Rails 8.1 and later also have `Rails.event`.

Field names match the repository's existing ones. Where none exists, prefer an
OpenTelemetry semantic attribute name (`http.response.status_code`,
`db.collection.name`, `error.type`) over inventing `status`, `table`, `errType`.

### Levels

| Level | OTel severity | Use it for | The mistake |
| --- | --- | --- | --- |
| `error` | 17-20 | A failure the service could not handle that needs a human | A client's bad input logged at `error`. A 400 is the API working. |
| `warn` | 13-16 | Recovered but degraded, or heading for failure: a retry that eventually succeeded, a fallback taken, a quota near its limit | Routine events logged at `warn` "so they show up". A `warn` nobody acts on trains everyone to ignore all of them. |
| `info` | 9-12 | State transitions and business events an operator wants in a timeline, roughly one per unit of work | An error logged at `info` with the stack dropped. Also one `info` per loop iteration. |
| `debug` | 5-8 | Detail a developer needs to reproduce a problem, structured and off by default | A temporary `"here"` line committed as if it were one of these. |
| `trace` | 1-4 | Very fine-grained detail, disabled everywhere by default | Using it where `debug` would do. |

- **`console.log`, `puts`, `p`, and `fmt.Println` are not logging.** They bypass
  level control, structure, redaction, sampling, and correlation. Never in
  committed code.
- **A line you added to find a bug is not a `debug` log.** It either becomes a
  real, structured log at the level it deserves, or it gets deleted. A deliberate
  `debug` log that is disabled in production is fine to commit; a leftover
  diagnostic is not.
- **The level a message deserves does not change because you want to see it
  today.** Raise the deployed level instead of promoting the line.

### One detailed record per failed operation, at the boundary that handles it

An error reported at every frame produces five records for one failure, each with
different partial context, and none of them the one you need.

Distinguish two different things:

- **The detailed record**: a structured `error` log, an error-reporter event, or
  a span exception. It carries the cause chain and the context. **Emit exactly
  one, using whichever mechanism the repository already uses.** A full error log
  plus a reporter event plus a recorded span exception is the same failure three
  times, in three tools, at three costs.
- **State markers**: the span status set to `Error` with `error.type`, and
  `error.type` on the operation's existing metric. These are cheap, aggregate,
  and are not duplicates of the detailed record. Set them when this code owns the
  operation and auto-instrumentation has not already done it.

```go
// ❌ logged here, and again by the caller, and again by its caller
func (s *Store) Get(ctx context.Context, id string) (*Order, error) {
	var o Order
	if err := s.db.QueryRowContext(ctx, getOrder, id).Scan(&o.ID, &o.Status); err != nil {
		slog.ErrorContext(ctx, "query failed", slog.Any("error", err))
		return nil, err
	}
	return &o, nil
}

// ✅ classify absence, add context, return; the boundary decides what happens
func (s *Store) Get(ctx context.Context, id string) (*Order, error) {
	var o Order
	err := s.db.QueryRowContext(ctx, getOrder, id).Scan(&o.ID, &o.Status)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrOrderNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("get order %s: %w", id, err)
	}
	return &o, nil
}
```

```go
// the boundary reports once, and an expected miss is not a failure
order, err := h.store.Get(ctx, id)
switch {
case errors.Is(err, ErrOrderNotFound):
	http.Error(w, "not found", http.StatusNotFound)
	return
case err != nil:
	slog.ErrorContext(ctx, "order lookup failed",
		slog.String("order_id", id),
		slog.Any("error", err),
	)
	http.Error(w, "internal error", http.StatusInternalServerError)
	return
}
```

- The boundary is whatever decides what happens next: the request handler, the
  job runner, the consumer loop, the top of a worker.
- Below the boundary, wrap and return. `fmt.Errorf("...: %w", err)` in Go,
  `new Error("...", { cause: err })` in JavaScript, a wrapping exception that
  keeps the original in Ruby.
- **Do not emit the detailed record and then rethrow toward another boundary that
  will emit it again.** Rethrowing after reporting is correct only when this is
  the terminal reporting boundary and the rethrow exists to tell the runtime the
  job failed or should retry. `Rails.error.record` is exactly that shape.
- **Preserve the cause chain, and know what your tools actually preserve.**
  - Go: `%w` preserves error identity for `errors.Is` and `errors.As`. It does
    **not** capture a stack, Go errors carry none by default, and `slog`'s
    built-in handlers serialize an error by calling `Error()`, producing a
    string. If stack traces matter, look for the mechanism the repository already
    has (a stack-capturing error package, or the error reporter's SDK). If there
    is none, propose one and ask rather than assuming `slog.Any("error", err)`
    gives you a stack.
  - Pino: `logger.error({ err }, "message")`. The `err` key is the default
    (`errorKey`). `pino.stdSerializers.errWithCause` keeps nested `cause` objects
    where the default serializer flattens them; behavior differs across versions,
    so check the installed one.
  - JavaScript: `cause` is non-enumerable, so `JSON.stringify` silently drops it,
    and its value can be any type. Normalize before reading `.message` or
    `.stack`.
  - Ruby: hand the exception object to the reporter, never its message.

### Carry the context

A log line nobody can correlate is a log line nobody can use. Every log emitted
while handling a request or a job needs the trace and span ids and the
identifiers of the thing being acted on. The OTel log data model has `TraceId`,
`SpanId`, and `TraceFlags` fields for exactly this.

Trace ids do not appear by themselves. They come from a log bridge, an
instrumented logger, or a handler that reads them off the active context. Check
that the repository has one wired up, and read real output to confirm the ids are
present. A child logger and a context-aware call signature give you the
plumbing, not the correlation.

**Bind the context once. Do not pass it by hand.** A field repeated at every call
site will be missing from the one call that matters.

```ts
// ❌ restated everywhere, and one of them forgets
logger.info({ requestId, tenantId, orderId }, "order validated");
logger.info({ requestId, orderId }, "payment authorized"); // tenantId lost

// ✅ bind at the boundary; every child line inherits it
const log = logger.child({ requestId, tenantId });
log.info({ orderId }, "order validated");
log.info({ orderId }, "payment authorized");
```

- Go: `logger := slog.With("request_id", id)`, then thread `ctx` and use
  `InfoContext` or `LogAttrs` so the handler can pull trace ids off the context.
- Ruby: `ActiveSupport::TaggedLogging` with `Rails.logger.tagged(request_id) { }`,
  and `Rails.error.set_context(...)` for the error reporter.
- Baggage crosses process boundaries in a plain header, is visible to anyone
  inspecting traffic, and reaches third parties through auto-instrumented
  outbound calls. Nothing sensitive goes in it.

### Volume and cost

**No unsampled per-item log inside a loop whose iteration count comes from
input.** Log the batch once, with bounded memory.

```ts
// ❌ one line per item, and every error object retained
for (const row of rows) {
  logger.info({ rowId: row.id }, "importing row");
  try { await importRow(row); } catch { /* keep going */ }
}

// ✅ one event, bounded sample, bounded memory, no raw error object
const SAMPLE_LIMIT = 5;
let failed = 0;
const sample: string[] = [];
const errorTypes = new Set<string>();

for (const row of rows) {
  try {
    await importRow(row);
  } catch (err) {
    failed += 1;
    if (sample.length < SAMPLE_LIMIT) sample.push(row.id);
    errorTypes.add(classifyError(err)); // bounded, documented set
  }
}

logger.info(
  { total: rows.length, failed, sample, errorTypes: [...errorTypes] },
  "import finished",
);
```

Failed rows are an expected partial result here, so this is a count, not an
exception report: bounded identifiers and bounded error classes, and no raw error
object at `info`. If a failed row instead means the whole import failed, that is
one failed operation, and it gets one detailed record at the boundary that owns
it.

- **A count you need in aggregate is usually a metric, not a log.** A metric's
  cost scales with the number of series; a log's cost scales with the number of
  events, at every hop. A metric is cheaper for rates and counts, but it is not
  free: it holds a series for the retention period and needs someone who will
  look at it.
- **Sample when you need examples rather than totals.** Log the first N per
  window or a fixed fraction, and keep a counter for the real number.
- A per-request log line is defensible, but in a high-traffic service it is
  frequently the single largest log source, and an access log or the request span
  may already cover it. Check before adding one.

## Metrics

| Instrument | For | Examples |
| --- | --- | --- |
| Counter | A monotonically increasing count of events | requests, errors, retries, messages processed |
| UpDownCounter | A value that rises and falls, derivable from events the code observes | in-flight requests, open connections |
| Gauge (usually observable) | A value read at collection time that events cannot derive | memory in use, pool size, broker-reported queue depth |
| Histogram | A distribution you need percentiles from | latency, payload size, batch size |

### Latency is a histogram, never an average

If 99 requests take 10ms and one takes 10s, the average is 110ms, every dashboard
looks healthy, and one user in a hundred is timing out. A percentile cannot be
recovered from an average, and percentiles cannot be averaged across instances.
Record the distribution and compute the percentile at query time.

OTel's stable HTTP duration metrics, `http.server.request.duration` and
`http.client.request.duration`, are histograms measured in **seconds**, with
advisory bucket boundaries given in the spec. Auto-instrumentation normally owns
them. Set explicit boundaries only for a domain histogram whose useful range
differs.

### Cardinality discipline

Every distinct combination of label values is a separate time series, stored and
indexed for the retention period. Adding one innocent-looking label is the
fastest way to degrade a metrics backend. Prometheus states the rule directly:
high-cardinality dimensions such as user ids, email addresses, and other
unbounded sets do not belong in labels.

| Safe as a label | Never a label |
| --- | --- |
| HTTP method, status code, route template (`/orders/{id}`) | User id, tenant id, session id, request id, trace id |
| Operation or handler name from a fixed set | Email address, username, IP address |
| Queue or topic name, when the set is fixed in code | Full URL, or a path with parameters substituted in |
| Error class from a documented set, plus `_OTHER` | Exception message, SQL text, stack frame, file path |
| Region, environment, service version | Timestamp, duration, or any other continuous value |
| Bounded outcome flags: `cache_hit`, `retried` | Anything from user input without an allowlist |

```ts
// ❌ one time series per user and per distinct path, forever
requestDuration.record(seconds, { "user.id": user.id, "url.path": req.url });

// ✅ bounded label set; the ids live on the span and in the log
requestDuration.record(seconds, {
  "http.request.method": req.method,
  "http.route": route,
  "http.response.status_code": res.statusCode,
});
```

- **If you cannot write down the complete set of values, it is not a label.**
- The OTel metrics SDK specification defines a **default cardinality limit of
  2000** series per metric per collection cycle, past which everything collapses
  into one point marked `otel.metric.overflow`. Nothing errors; the metric
  silently stops being useful. Support and defaults vary by SDK and version, so
  verify the installed one.
- **One metric with an outcome attribute, not a success metric and a failure
  metric.** Set `error.type` on failure, leave it unset on success. OTel: "It's
  RECOMMENDED to report one metric that includes successes and failures as
  opposed to reporting two (or more) metrics." Follow the repository if it
  already does otherwise.
- A recovered failure is not a failed operation. A fallback or retry counter
  records degradation; it does not put `error.type` on an operation that
  completed successfully.
- **Never derive a label from a request header.** Whoever controls the header
  controls your cardinality. The HTTP semconv says exactly this about
  `server.address` on server metrics.

### Naming and units

- Lowercase. `.` separates namespaces, `snake_case` inside a component:
  `http.response.status_code`.
- Do not pluralize namespaces. Pluralize a metric name only when the unit is a
  count annotation such as `{fault}`. Never pluralize an UpDownCounter.
- **Do not append `_total`.** OTel avoids it on counters and UpDownCounters both.
- Units are UCUM and live in metadata (`metric.WithUnit` in Go, the `unit`
  option in JS), not in the name. Durations are **seconds** (`s`). Bytes are
  `By`. Ratios are `1`.
- Prefix custom metrics with your own namespace, never an existing OTel one.
- Check whether a convention already names it before inventing a name.

**Prometheus recommends the opposite scheme**: base units in the name with a
plural suffix and `_total` on counters (`http_request_duration_seconds`). Both
positions are current. Follow whichever the repository and its backend use, and
never mix the two in one service.

## Traces

### Span at boundaries, and end every span you start

- **When a span is the smallest missing signal, create one per operation
  boundary**, not one per function: an inbound request, an outbound call, a
  query, a queue publish or consume, a job run, a named unit of expensive work. A
  boundary auto-instrumentation already covers needs no new span, and a trace
  with 400 spans is as unreadable as no trace.
- Check auto-instrumentation first. If `@opentelemetry/instrumentation-http` or
  `otelhttp` is registered, the server and client spans exist. Enrich the active
  span rather than nesting a duplicate:

```ts
trace.getActiveSpan()?.setAttribute("order.id", orderId);
```

- **A span you start manually must end on every path, including the error path.**
  JavaScript's `startActiveSpan` does not end the span for you: call `span.end()`
  in a `finally`. In Go, `defer span.End()` on the line after `Start`. In Ruby,
  prefer `in_span`, which ends the span itself.

### Span names must be low cardinality

A span name is what traces are grouped and aggregated by. An id in the name makes
every trace its own group and every latency aggregate meaningless.

> ❌ `GET /orders/8f21c3/items`, `process order 8f21c3`,
> `SELECT * FROM orders WHERE id = '8f21c3'`

> ✅ `GET /orders/{id}/items`, `process orders.created`, `SELECT orders`

OTel's rule for HTTP is `{method} {target}`, where the target is `http.route` on
the server side, and the spec is explicit: "Instrumentation MUST NOT default to
using URI path as a `{target}`."

Identifiers belong in attributes, where cost is per span rather than per series.
That is far more tolerant than a metric label. It is not free, and it is not an
exemption from the redaction rules below.

### Use the current attribute names

These were renamed. The old names still appear in older instrumentation, blog
posts, and model memory. Confirm against the semconv version the repository's SDK
actually pins.

| Do not use | Use |
| --- | --- |
| `http.method`, `http.status_code` | `http.request.method`, `http.response.status_code` |
| `http.url`, `http.target`, `http.scheme` | `url.full`, `url.path` and `url.query`, `url.scheme` |
| `http.user_agent`, `http.flavor`, `http.client_ip` | `user_agent.original`, `network.protocol.version`, `client.address` |
| `net.peer.name`, `net.host.name`, `net.peer.port` | `server.address`, `server.port` |
| `db.system`, `db.statement`, `db.operation` | `db.system.name`, `db.query.text`, `db.operation.name` |
| `db.sql.table`, `db.mongodb.collection` | `db.collection.name` |
| `db.name`, `db.redis.database_index` | folded into `db.namespace` |
| `db.user`, `db.connection_string` | removed, with no replacement |

Several `db.system.name` values were renamed too (`mssql` became
`microsoft.sql_server`, `dynamodb` became `aws.dynamodb`). Messaging conventions
are still experimental; use them, but do not treat them as settled the way HTTP
and database attributes are.

### Status and errors on a span

- **Leave the status unset on success.** Instrumentation should not set `Ok`.
- On failure, set `Error` and set `error.type` to a value from a bounded set your
  code documents.
- **`recordException` and `RecordError` do not set the status.** Pair them.
- **Do not record an exception the code handled and recovered from.** OTel:
  "Errors that were retried or handled (allowing an operation to complete
  gracefully) SHOULD NOT be recorded on spans or metrics that describe this
  operation."
- Do not record the same exception twice as it propagates, and do not record a
  span exception when the repository's error reporter is already producing the
  one detailed record for this failure.
- HTTP specifics: a 4xx leaves a **server** span unset, because a client's bad
  request is not your failure, and marks a **client** span as error. A 5xx is an
  error on both.
- **Mark the span for the operation that failed, not whatever span is active.**
  The active span is often the whole inbound request, which may still succeed
  after the caller falls back. Set the status in code that owns the span.
- **The status description is telemetry.** Do not pass a raw error message
  through when it can contain user input, a URL, query text, or a token.

```ts
return tracer.startActiveSpan("charge card", async (span) => {
  try {
    return await chargeCard(order);
  } catch (err) {
    span.setAttribute("error.type", classifyError(err)); // bounded, documented set
    span.setStatus({ code: SpanStatusCode.ERROR });
    throw err;
  } finally {
    span.end();
  }
});
```

```go
ctx, span := tracer.Start(ctx, "charge card")
defer span.End()

if err := chargeCard(ctx, order); err != nil {
	span.SetAttributes(attribute.String("error.type", classifyError(err)))
	span.SetStatus(codes.Error, "charge failed")
	return err
}
```

```ruby
# in_span sets Status.error on an escaping exception and finishes the span.
# record_exception defaults to true, so pass false when the error reporter is
# already producing the one detailed record.
tracer.in_span("charge card", record_exception: false) do |span|
  span.set_attribute("order.id", order.id)
  charge(order)
end
```

`classifyError` maps to a set the package documents, using `errors.Is` and
`errors.As` in Go or an `instanceof` chain in TypeScript. Do not reach for
`fmt.Sprintf("%T", err)`: on a wrapped error it returns `*fmt.wrapError`, and
concrete implementation types are unstable and make a poor dashboard contract.
OTel: "The `error.type` value SHOULD be predictable and SHOULD have low
cardinality. Instrumentations SHOULD document the list of errors they report."

### Propagation is where traces break

A trace stops at the first boundary that drops the context, and everything past
it becomes an orphan root span. This is the most common tracing bug and it is
silent: both halves look correct on their own.

**JavaScript.** `context.active()` returns `ROOT_CONTEXT` unless a context
manager is registered. `startActiveSpan` activates for the duration of its
callback; `startSpan` activates nothing. `context.with` runs a function
immediately under a given context, so wrapping it in a callback reads the context
at the wrong moment. Use `context.bind`, which captures the context now and
restores it later:

```ts
// ❌ context.active() runs when the event fires, not at registration, so it
// picks up whatever is active then, which is usually ROOT_CONTEXT
emitter.on("done", () => context.with(context.active(), handle));

// ✅ bind captures the context active now and restores it when handle runs
emitter.on("done", context.bind(context.active(), handle));
```

**Go.** Context travels only in `context.Context`. `tracer.Start` returns a new
`ctx` that must be passed down, so a goroutine started without it loses the
trace.

```go
// ❌ the goroutine starts a new, parentless trace
go publish(order)

// ✅ keep the values, drop only the cancellation, and give it its own bound
bg, cancel := context.WithTimeout(context.WithoutCancel(ctx), 30*time.Second)
go func() {
	defer cancel()
	publish(bg, order)
}()
```

`context.WithoutCancel` (Go 1.21) keeps values, and therefore the span context,
while removing the deadline and cancellation. That leaves the work with no
lifecycle bound at all, so give it one.

**Ruby.** `OpenTelemetry::Context.current` is fiber-local. Work handed to a
thread pool or a background job carries nothing unless you pass the context and
re-enter it with `OpenTelemetry::Context.with_current(ctx)`.

**Across processes.** Context crosses only inside the message or the request, in
the fields the configured propagator writes, including `traceparent` and
possibly `tracestate` and baggage. The propagator does the inject and extract,
and client auto-instrumentation usually calls it. Verify rather than assume, and
check the message envelope even has a header field.

**Test it.** Make one request that crosses the new boundary and confirm the
downstream span carries the same trace id. A trace that looks correct in one
service and starts fresh in the next is the bug.

## Errors

### Every caught error does exactly one of three things

| Do this | When | What it looks like |
| --- | --- | --- |
| **Handle it** | There is a defined fallback with known semantics and the caller genuinely does not need to know | Return the cached value, use the default, skip the optional enrichment. Count the degradation, or log at `warn` if it should be visible. |
| **Enrich and rethrow** | You know something about the operation the caller does not, but the caller decides what happens | Wrap with the operation and the identifiers, preserving the cause. Do not report here. |
| **Report it** | You are the boundary and a human needs to know | Emit the one detailed record, set the status on the span you own, add the failure outcome to the operation's existing metric where the code records one, and decide the response. |

A `catch` that does none of these is a swallowed error. `catch {}`, `rescue nil`,
`catch { return [] }`, and `if err != nil { return nil }` each turn a failure into
a wrong answer that flows downstream and gets stored as truth.

```ts
// ❌ a network failure becomes "this user has no orders", which then gets cached
try {
  return await api.listOrders(userId);
} catch {
  return [];
}

// ✅ the caller can tell an empty list from a broken dependency
try {
  return await api.listOrders(userId);
} catch (err) {
  throw new Error(`list orders for user ${userId}`, { cause: err });
}
```

An identifier in a wrapped message is idiomatic and useful, and it ends up in
whatever detailed record reports the failure. Use an identifier the repository's
data policy allows in telemetry, not an email address or another direct
identifier.

### What makes a report actionable

Someone reads it once, months later, with no memory of the code. It needs the
cause chain rather than `err.message`, the operation attempted stated in the
message ("charge card", not "error"), the identifiers that locate the record, the
trace id, and what the code did next: retried, fell back, returned a 500.

```ruby
# ❌ context lost, stack discarded, and the caller cannot tell it failed
begin
  charge(order)
rescue => e
  Rails.logger.error e.message
end

# ✅ one authoritative report with context, and the failure still propagates
Rails.error.record(context: { order_id: order.id, amount_cents: order.amount_cents }) do
  charge(order)
end
```

`Rails.error.record` reports and re-raises. `Rails.error.handle` reports and
swallows, returning the result of the `fallback:` callable, so use it only where
a real fallback exists:
`Rails.error.handle(fallback: -> { User.anonymous }) { User.find_by(params) }`.
Where the reporter is configured, that report **is** the detailed record. Do not
also log the exception.

## Never put this in telemetry

A hard rule, applying to log fields, log messages, span attributes, span names,
span status descriptions, metric labels, error reports, and baggage. Telemetry is
retained, replicated, shipped to a vendor, and readable by everyone with
dashboard access.

Never record passwords, tokens, API keys, session cookies, `Authorization`
headers, signing secrets, private keys, or connection strings with credentials.
Never record full request or response bodies or whole header maps, which carry
all of the above by construction. Never record PII, payment data, or
special-category data such as health and biometrics. Never record raw SQL with
literal values, or raw user input echoed back.

**An exception message is telemetry too.** It routinely contains the URL that
failed, the query that was rejected, or the value that failed validation.
Key-path redaction cannot reach inside a message string. Use the repository's
error serialization and pipeline filtering, and where no safe mechanism exists,
do not emit the raw error object at all.

### When you need the field to debug

| Instead of | Record |
| --- | --- |
| The email address | An identifier the repository's data policy allows in telemetry. A persistent user id may itself be personal data; check rather than assume. |
| The token | A stable hash prefix, its id or `jti`, or just its scopes and expiry |
| The full body | The field names present, the size, and the ids inside it |
| The card number | The last four and the brand |
| The raw query with values | The parameterized query text, literals replaced with `?` |
| The whole header map | An allowlist of the headers the code actually reads |

Use the redaction the tooling already provides rather than remembering it at
every call site:

- **Pino:** `redact: { paths: ['req.headers.authorization', '*.password', '*.token'], censor: '[Redacted]' }`.
- **Rails:** `config.filter_parameters` and `ActiveSupport::ParameterFilter`,
  which also filter sensitive columns when `#inspect` is called on an Active
  Record object. Read the app's initializer; the generated default list has grown
  across versions.
- **Go:** `slog.HandlerOptions.ReplaceAttr` to mask keys centrally, or implement
  `slog.LogValuer` on the type so it can never serialize itself in full. The
  `log/slog` docs give this example: a `Token` type whose `LogValue` returns
  `slog.StringValue("REDACTED_TOKEN")`.

For query text, OTel says to sanitize by replacing literals with `?`, and
explicitly says **not** to sanitize already-parameterized text, because the
parameters are exactly where the sensitive values are. Never enable
`db.query.parameter.<key>` capture by default.

**Redaction is not something you add later.** A field that reached the pipeline
has been retained somewhere.

## Instrumentation must not change behavior

- **No telemetry call can throw.** Do not serialize a possibly-circular object
  into a field, do not dereference a possibly-null value inside a log argument,
  and do not let a custom serializer run logic that can fail.
- **Do not pay for a message that will not be emitted.** Guard expensive work
  behind the level check: `logger.isLevelEnabled('debug')` in Pino,
  `logger.Enabled(ctx, slog.LevelDebug)` in Go, and the block form
  `Rails.logger.debug { expensive_string }` in Ruby so the string is never built.
- **No blocking I/O on a hot path to emit telemetry.** Write structured output to
  stdout and let the collector ship it, or use the SDK's batching exporter. Never
  a synchronous HTTP request per event.
- **No behavior that depends on a telemetry call.** If deleting the line changes
  the result, it is not a log line.
- **Export failure must not fail the request.** Confirm the exporter drops rather
  than blocks when its queue is full.

## Alerts, dashboards, and health

The four golden signals are latency, traffic, errors, and saturation
([Google SRE Book](https://sre.google/sre-book/monitoring-distributed-systems/)).
Read latency for successful and failed requests separately, since a fast failure
otherwise makes the graph look better. That is normally the same histogram
grouped by a bounded outcome attribute, not two histograms.

**A new signal needs a consumer.** A dashboard, an alert, incident search, trace
exploration, a runbook step, or a support workflow all count. Something nobody
will ever look at does not. Most new metrics need no alert at all.

What is worth paging on:

- **Symptoms, not causes.** Users do not care that a pod restarted; they care
  that their requests fail. Cause-based alerts are for conditions with no symptom
  until it is too late: disk filling, quota nearing a limit, certificate expiry.
- **Urgent, important, actionable, and real.** If the response is mechanical,
  automate it. If nobody acts on it, delete it.
- Prefer an SLO burn-rate alert to a static threshold. Multi-window,
  multi-burn-rate is the recommended shape, and each tier needs both windows over
  the threshold (for a 99.9% SLO: page at burn rate 14.4 over 1 hour with a 5
  minute short window, page at 6 over 6 hours with 30 minutes, ticket at 1 over 3
  days with 6 hours).

Two failure modes nothing else catches, when the work matters to a user or the
business and the platform does not already monitor it:

- **A job that matters needs an alert on silence**, not just on failure. "Has not
  completed successfully in N intervals" is what a failure counter misses
  entirely. Best-effort cleanup and optional enrichment do not need one.
- **A consumer that matters needs lag or depth, and a dead-letter alert.**

Liveness answers "should this be restarted". Readiness answers "should this
receive traffic". Never put a dependency check in liveness: a database blip
should not restart every pod at once. Add a new dependency to readiness only if
requests genuinely fail without it.

### When you are debugging and the signal is not there

Add the instrumentation you needed **as part of the fix**, at the right level,
and leave it in. Do not ship a temporary diagnostic and delete it afterwards:
either the signal is worth keeping, in which case make it a real log or metric,
or it is not, in which case use a debugger. If you found the bug by reading code
because telemetry could not tell you, that gap is a finding worth reporting.

## Workflow

1. **Read the repository's telemetry before writing any.** Logger, SDK,
   registered auto-instrumentation, error reporter, field names, level
   convention, metric prefix, and where it all exports to.
2. **List the boundaries the change touches.** That is the candidate set. Nothing
   off it needs instrumentation by default.
3. **For each candidate, name the unanswered operational question.** If the
   existing signal answers it, add nothing and record that decision.
4. **Add the smallest signal that answers the question.** One, usually. Not one
   of each.
5. **Write it with current names and bounded cardinality.** Semantic conventions
   where the repository has no convention of its own, no unbounded label, low
   cardinality span names.
6. **Check the failure path.** One detailed record at the boundary, span status
   and metric outcome as markers, every manually started span ended, context
   propagated across every new async or process edge.
7. **Walk the redaction list** over every field, attribute, label, and message
   you added, including error messages.
8. **Run it and read the actual output.** A field that does not serialize, a span
   with no parent, or a typo in a metric name all look fine in a diff.
9. **Follow the repository's telemetry tests.** If it asserts on log output or
   exported spans, add assertions. Do not introduce a new testing tool.
10. **Report the decisions,** including every place you decided instrumentation
    was not warranted.

## Sources

- OpenTelemetry semantic conventions, and the [HTTP](https://opentelemetry.io/docs/specs/semconv/non-normative/http-migration/) and [database](https://opentelemetry.io/docs/specs/semconv/non-normative/db-migration/) attribute migration guides: <https://opentelemetry.io/docs/specs/semconv/>
- [Naming and units](https://opentelemetry.io/docs/specs/semconv/general/naming/) · [Recording errors](https://opentelemetry.io/docs/specs/semconv/general/recording-errors/) · [Logs data model](https://opentelemetry.io/docs/specs/otel/logs/data-model/) · [Cardinality limits](https://opentelemetry.io/docs/specs/otel/metrics/sdk/#cardinality-limits) · [Baggage security](https://opentelemetry.io/docs/concepts/signals/baggage/#baggage-security-considerations)
- [Prometheus metric and label naming](https://prometheus.io/docs/practices/naming/)
- Google SRE: [Monitoring Distributed Systems](https://sre.google/sre-book/monitoring-distributed-systems/) · [Alerting on SLOs](https://sre.google/workbook/alerting-on-slos/)
- [Kubernetes structured logging conventions](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-instrumentation/logging.md)
- [Go `log/slog`](https://pkg.go.dev/log/slog) · [Pino](https://getpino.io/#/docs/api) · [Rails error reporting](https://guides.rubyonrails.org/error_reporting.html)

## Before you finish (checklist)

- [ ] Every boundary the change touches was considered, and the ones needing no
      signal are stated as decisions in the report rather than left unmentioned.
- [ ] Each new signal answers a named operational question that existing
      telemetry and auto-instrumentation did not already answer.
- [ ] The repository's logger, SDK, error reporter, field names, and level
      conventions were followed, and no telemetry dependency was added without
      approval.
- [ ] Log messages are static strings with variable data in fields, at the right
      level, with no leftover diagnostic, `console.log`, or `puts`.
- [ ] Each failed operation produces exactly one detailed record, at the boundary
      that handles it, with the cause chain intact. No `catch` swallows an error.
- [ ] No unsampled per-item logging, no unbounded in-memory accumulation, and no
      metric label whose value set you cannot write down.
- [ ] Span names are low cardinality, every manually started span ends on every
      path, status is unset on success and `Error` with a bounded `error.type` on
      failure.
- [ ] Context propagates across every async, thread, queue, and process boundary
      the change adds, verified by one trace id end to end.
- [ ] No secret, credential, header map, body, or PII appears in any field,
      attribute, label, status description, report, or baggage entry, and no
      unsanitized error message reaches a span status or a metric label.
- [ ] No telemetry call can throw, nothing expensive runs at a disabled level,
      and nothing blocks a hot path to emit telemetry.
- [ ] Any new alert is symptom-based and actionable, and any new signal has a
      consumer.
- [ ] The output was run and read, not inferred from the diff.
