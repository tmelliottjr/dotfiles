---
name: design-code-change
description: >
  Use this skill before implementing any change that has more than one credible
  approach, and whenever the user asks how to implement, design, structure,
  architect, refactor, model, or fix something, asks for the best or right
  approach, asks which option to pick, or asks for a review, critique, or second
  opinion on a design or an implementation (for example "how should I do this",
  "what's the best way", "which approach", "design this", "refactor this", "is
  this the right way", "compare these options", "review this design"). It ranks
  options by correctness, then by real precedent in the repository and the
  ecosystem, then by performance, and it forces implementation cost to be stated
  as a tradeoff rather than used as the deciding factor.
---

# Designing a Code Change

Pick the option that is right, not the option that is cheap. Cost is real and it
belongs in the conversation, but it is one input to the decision, never the thing
that settles it.

The failure this skill exists to prevent is a recommendation that was chosen for
its small diff and then justified after the fact. That looks like a local patch
where the fix belonged one level down, a special case bolted onto an abstraction
that should have been corrected, or a missing index, transaction, or lock,
because a simpler shape passed the happy path.

## The order that decides it

1. **Correct.** It produces the right result on every supported input and every
   failure it can realistically encounter, including under concurrency and at
   real data sizes.
2. **Conventional.** It matches how this repository already solves adjacent
   problems, and failing that, how the leading projects in the ecosystem solve
   this problem.
3. **Performant.** Its shape has no performance cliff built into it.

Implementation cost is not on this list. It is an input you disclose, not a rank
you sort by. A correct option that is more work beats a cheaper option that is
wrong, and the user decides whether to pay, after being told what the cheaper one
gives up.

Convention decides between designs that are all correct. When the repository's
established pattern would make this case incorrect, correctness wins: do not copy
the defect, fix it at the right level, and keep the deviation scoped to this case
rather than starting a migration.

## Fix it at the right level

Before writing the fix, answer three questions:

- **Where does this actually go wrong?** The place the symptom appears is often
  not the place the mistake is made. An `undefined` guard in a component is a fix
  for a loader that can return an incomplete object.
- **If I fix it here, does the same bug still exist somewhere else?** If yes, the
  fix is at the wrong level. Every other caller has the same hole.
- **Is this the second or third special case?** One special case is a special
  case. Three are a signal the abstraction has the wrong shape, and adding a
  fourth is compounding the problem.

Fixing at the right level is not the same as widening scope. Scope is set by
whether the code participates in the same invariant, not by how many lines or
files it spans, and correcting the same defect for every caller of a broken
abstraction is part of the fix. When the fix at the right level really is
materially larger than what was asked, say so, propose it, and ask. Do not
quietly patch the symptom instead.

> ❌ The date parser breaks on `2026-02-29`, so the caller now checks for
> February before calling it.

> ✅ The date parser rejects invalid dates and returns a typed error. The caller
> handles the error. The other six callers stop being wrong too.

## Correctness first

A change is not correct because the happy path passes. Walk these before choosing
a shape, and name in your report the ones that apply.

| Area | The question | A failure it catches |
| --- | --- | --- |
| Edge cases | What are the empty, single, boundary, duplicate, and maximum inputs? | `hasNext = items.length === pageSize` requests an extra empty page whenever the total is an exact multiple of the page size. |
| Error paths | For each call that can fail, what happens next? | `catch { return [] }` turns a network failure into "the user has no items", which then gets saved as truth. |
| Partial failure | If step 3 of 5 fails, what is left behind? | A loop that creates three resources and dies on the second, orphaning the first with no way to resume or roll back. |
| Ordering | Can responses or events arrive in a different order than they were issued? | A search box where the slow response for `ab` overwrites the fast response for `abcd`. |
| Concurrency | What if two of these run at once on the same data? | Two requests both read `balance = 100`, both write `90`, and one withdrawal disappears. |
| Resource lifecycle | What creates this, and what is guaranteed to release it? | A subscription, timer, listener, file handle, or connection with no removal path, on a code path that runs per render or per request. |
| Data integrity | Which invariants must hold across rows, tables, or services, and what enforces them? | A cache added for speed with no invalidation path, which produces wrong answers rather than slow ones. |
| Behavior at scale | What changes at 100x the data, 100x the concurrency, or a 10x slower network? | An unbounded fetch that is fine on 50 rows in dev and times out on 500,000 in production. |

Two rules that follow from the table:

- **An error you cannot handle is an error you propagate.** Swallowing it does
  not make the system work, it makes the failure silent and moves the damage
  somewhere harder to find.
- **Correctness under concurrency is a design decision, not a detail.** Pick the
  primitive deliberately (a transaction, a unique constraint, an optimistic
  version column, a lock, an idempotency key, a request token, an abort signal)
  and say which one and why.

## Follow real precedent

Prefer the established pattern over an invention. Search in this order and stop
at the first level that answers the question.

1. **This repository.** How does the nearest sibling module, service, or feature
   solve the adjacent problem? Read it before you design. Repository conventions
   win, and matching them is the default.
2. **The ecosystem's leading projects.** How do the dominant framework, standard
   library, or widely adopted library solve this exact problem? Their solution
   has absorbed edge cases you have not thought of yet. For a retry policy, read
   how `urllib3.Retry`, `tenacity`, or the framework's own job-retry API handles
   backoff, jitter, and which errors are retryable, then adapt the parts that
   apply. Do not assume two libraries agree; they often make different choices.
3. **Your own design.** Only after the first two do not fit, and only with a
   stated reason why they do not.

Say where the pattern came from, in one line. It belongs in the final report
always, in the pull request only when it saves the reviewer context, and in a
code comment only when it explains a constraint the code cannot show.

> Mirrors the reducer shape in `packages/board-core`, so both boards handle load
> failures the same way.

> Full-jitter exponential backoff, following `tenacity.wait_random_exponential`,
> so retries do not synchronize after an outage.

"Industry best practice" is never a license to import a pattern this repository
does not use. If the repository's convention is worse on performance, clarity, or
maintainability but still correct here, follow the repository, say so in your
report, and describe the better pattern in one or two sentences so the user can
decide separately. Do not start a migration inside an unrelated change.

## Performance as a design property

This is not micro-optimization and not premature optimization. The point is
choosing a shape that does not have a cliff built into it, because the shape is
expensive to change later and the constant factors are not.

- **Algorithmic complexity.** Calling `.includes()` on an n-item array inside an
  n-iteration loop is O(n²). Build the `Set` or `Map` once outside the loop for
  average O(1) lookups. At 10 items nobody notices; at 10,000 it is up to 100
  million element comparisons.
- **N+1 access.** One query per row, one API call per item, one file read per
  entry. Batch it, join it, or preload it. It is invisible in a test with three
  fixtures and dominates the request in production.
- **Round trips.** Independent awaits run sequentially should run concurrently,
  bounded when the item count is not fixed, so the fix does not become a flood.
  Three dependent calls where the API offers one batched endpoint should be one.
- **Allocation and copying.** Rebuilding a large object or array on every
  iteration, render, or event. Copying a buffer to change one field. Watch for
  work that scales with data size on a path that runs per item.
- **Blocking the hot path.** Image processing, PDF generation, third-party calls,
  or large writes inside a request handler, a render, or an event loop tick.
  Decide deliberately whether it is inline, deferred, or queued.
- **Payload size.** Returning whole records when the caller needs three fields.
  Sending an unbounded list where the caller pages. Shipping a dependency to the
  client for one function.

State the complexity or the cost when it matters: "one query instead of one per
row", not "this should be faster".

## Never silently pick the cheap option

Recommend the option that wins on the ranking. A lower-ranked option is a
compromise the user chooses after hearing what it gives up, not one you choose
for them, and you do not build it unless they pick it.

If cost, diff size, review burden, or landing risk influenced the choice at all,
that is a tradeoff and it gets said out loud, with the better option named.

> ❌ Adding an `isArchived` check in the list component is the cleanest fix here.

> ✅ Adding the `isArchived` check in the list component works, but it is the
> third place that filters archived rows, and the next caller will forget. The
> better fix is an `active` query scope that the three existing call sites use,
> with an explicit opt-in for the one report that needs archived rows.
> Recommending that. The component check is available if you need this today.

Never describe an option as "cleanest", "simplest", or "most pragmatic" when what
you mean is "smallest to write". Those words claim a design property you have not
demonstrated.

## Presenting a tradeoff

Short, specific, decision-oriented. Two or three options at most. For each: what
it costs, what it buys, what breaks later. Then a recommendation and the reason
it wins. Never a neutral menu that hands the decision back.

> ❌ There are a few ways to go here. Option A is a quick fix that only touches
> one file, so it is low risk. Option B is a larger refactor and would take
> longer, but it is more thorough. Option C would be the most robust solution but
> is a significant amount of work. Happy to go with whichever you prefer.

> ✅ Two options for the stale-response bug:
>
> - **Sequence token.** Tag each request and drop responses that are not the
>   latest. Correct for out-of-order responses. One ref in the hook, plus a test
>   that resolves the two requests out of order. If the app already uses a
>   fetching library, use its mechanism instead: a distinct query key, or
>   cancellation with `AbortSignal`.
> - **Debounce to 300ms.** Two lines. Hides the bug in manual testing, still
>   loses the race on a slow network, and the next person to tune the debounce
>   brings it back.
>
> Recommend the sequence token. Debouncing leaves the ordering bug in the code
> and makes it harder to find later.

Rules for the format:

- Name each option for what it *is*, not "Option A".
- One line of cost, one line of what breaks later. No paragraph.
- The recommendation is a sentence, not a hedge. "Recommend X because Y."
- If two options are genuinely close, say what would decide it, then ask.

## When to ask, and when not

Most decisions do not need a question. Make the call, note it in one line, move
on. The first four below are exceptions to that: ask even when nothing about the
request is ambiguous, because the cost of being wrong lands on someone else.

**Ask before:**

- Changing a public contract: an exported API, a wire format or schema, a CLI
  flag, a database column others read, a published type.
- Writing, backfilling, deleting, or migrating existing persisted data, or
  changing a schema.
- Moving an authentication, authorization, tenancy, or trust boundary.
- Adding, replacing, or removing a dependency.
- Choosing between two options that are genuinely close, where the decider is
  something only the user knows (roadmap, traffic shape, deadline, who else
  consumes this).
- Discovering that the correct fix is materially larger than what was asked.

**Do not ask about:**

- Naming, file placement, test structure, formatting.
- Anything the repository's existing code already answers. Go read it.
- Anything reversible in a single follow-up commit.
- Permission to handle an error path, an edge case, or a concurrency hazard that
  the requested change plainly requires. That is the work, not an extra.

Ask once, in one message, with the options, a recommendation, and the default you
will take if the user does not care.

## Anti-patterns

These are the moves that make a symptom disappear without fixing anything. Name
them when you see them in review, and do not commit them.

| Anti-pattern | The tell | Instead |
| --- | --- | --- |
| Special case over abstraction | A new `if` branch for one caller, one type, or one tenant, next to two others like it | Change the abstraction so the case is not special |
| Swallowed error | `catch` with an empty body, a log line, or a default return value | Handle it or propagate it; a default that is indistinguishable from real data is data corruption |
| Type escape hatch | `any`, `as unknown as`, `# type: ignore`, `interface{}`, or a widened union added to silence the checker rather than to model a state the code handles | Fix the type or the shape it describes; the checker found a real gap |
| Copy instead of extract | The same block in two files, one with a small edit | Extract it, or accept the duplication explicitly and say why |
| Retry or sleep as a fix | `setTimeout`, `sleep(100)`, or a retry added until the flake stops | Find the ordering or readiness condition and wait on that condition |
| Flag that defers the decision | A new boolean or option whose only purpose is to avoid choosing a behavior | Pick the behavior; a config knob nobody sets is a decision the user now has to make |
| Loosened check | A skipped test, an added lint disable, a relaxed type, a lowered threshold, to make a change pass | Fix the code; if the rule is genuinely wrong, say so and change it deliberately, alone |
| Patch above the cause | A guard in the caller for a value the callee should never produce | Fix the callee, so the other callers stop being wrong too |

Each has a legitimate form, and the difference is whether it was chosen or
reached for:

- A `catch` is legitimate when the handler does something real: a fallback with
  known semantics, a typed error, a user-visible message.
- `any` is legitimate at a genuine untyped boundary (parsing external JSON, an
  untyped dependency), validated immediately and narrowed, with a comment saying
  why. Widening a union is legitimate when the runtime really produces that state
  and every consumer handles it.
- A retry is legitimate for genuinely transient failures, with backoff, a cap,
  and a rule for which errors are retryable.
- A flag is legitimate for a rollout, a migration, or a real per-environment
  difference, with an owner and a removal plan.
- A disabled lint rule is legitimate when the rule is wrong for that line, with a
  comment saying why, and never as a blanket file or directory exclusion.
- Duplication is legitimate when the two copies are genuinely unrelated and will
  diverge. Say that is the reason.

## What "done" means

- **Each failure mode you named has a regression test,** where the repository's
  existing tooling can reproduce it. If you identified an ordering bug, the test
  fails without the fix and exercises the interleaving (controlled promises, fake
  timers, a seeded scheduler), not one that calls the function twice and passes
  either way.
- **Tests cover the error paths, not just the happy path.** The empty input, the
  rejected promise, the constraint violation, the second concurrent caller.
- **Behavior is verified, not assumed.** Run it. "Should work" is not evidence,
  and neither is "the types check".
- **Say what you did not verify.** Where a failure mode cannot be reproduced with
  the existing tooling (a third-party outage, resource exhaustion under real
  load), run the strongest targeted check available and name what is still
  unverified, in one line, rather than letting a clean summary imply coverage
  that does not exist.
- **Report the decision.** What you chose, what you passed over and why, and any
  correctness question you resolved by assumption.

## Workflow

1. **Restate the problem in one sentence, including the failure mode.** "Two
   concurrent withdrawals can both read the same balance", not "fix the balance
   bug". If you cannot name the failure mode, you are not ready to pick a design.
2. **Read the precedent.** The nearest sibling in this repository first, then the
   ecosystem's dominant solution to the same problem.
3. **List the credible options,** usually two or three. At least one must be the
   fix at the right level, even when it is bigger than what was asked.
4. **Test each against the order:** correct, then conventional, then performant.
   Walk the correctness table for the ones that apply.
5. **Recommend the one that wins,** and build that one. If the user should
   consider a cheaper compromise, present it as a compromise with what it gives
   up, and wait for them to choose it.
6. **Ask only if it hits the ask list.** Otherwise decide and note it.
7. **Build it,** with tests that cover the failure modes you named in step 1.
8. **Report** what you chose, what you passed over, and what you did not verify.

## Before you finish (checklist)

- [ ] The failure mode is named in one sentence, not just the symptom.
- [ ] The fix is at the level where the mistake happens, not where it shows up.
- [ ] Edge cases, error paths, partial failure, ordering, concurrency, resource
      lifecycle, data integrity, and behavior at scale were each considered, and
      the ones that apply are handled.
- [ ] The pattern follows this repository's adjacent code, or a named ecosystem
      precedent, and the source is stated.
- [ ] No performance cliff in the chosen shape: no accidental O(n²), no N+1, no
      avoidable round trips, no blocking work on a hot path.
- [ ] The recommended option is the one that wins on correctness, then precedent,
      then performance, and any cheaper option is presented as a compromise the
      user chooses.
- [ ] If cost, diff size, or landing risk influenced the choice, it is stated out
      loud with the better option named.
- [ ] Any tradeoff is presented with what it costs, what it buys, what breaks
      later, and a recommendation with its reason.
- [ ] No anti-pattern from the table was used, and any legitimate-looking form of
      one is justified in a comment or the report.
- [ ] Tests cover the failure modes, not just the happy path, and fail without
      the fix.
- [ ] Nothing is claimed complete without evidence, and anything unverified is
      named.
