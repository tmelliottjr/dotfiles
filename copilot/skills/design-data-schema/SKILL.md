---
name: design-data-schema
description: >
  Use this skill whenever the work involves how data is stored or queried: designing
  or reviewing a database schema, data model, table, column, or ERD, choosing types,
  keys, or constraints, adding or reviewing an index, analyzing query access patterns
  or a slow query, deciding between normalizing and denormalizing, modeling ordering
  or ranking, or planning a migration or backfill (for example "put together the
  proposed schema", "what tables do I need", "how should I store this", "what indexes
  does this need", "should this be a JSON column", "review this migration", "why is
  this query slow"). It also applies with no prompting when a change adds a table,
  column, index, migration, or query. It designs from the access patterns first, keeps
  invariants in the database rather than the application, and requires every schema
  change to be safe to deploy and reversible.
---

# Designing a Data Schema

Design the schema from the queries it has to serve, not from the nouns in the feature
description. Storage is the hardest layer to change after it ships, so the shape has to
be right before the data lands in it.

The failure this skill exists to prevent is a model that reads correctly and performs
terribly: tables derived from domain nouns, indexes added later to whatever turned out to
be slow, and invariants left to application code that concurrency then breaks. The second
failure is a migration that is correct in a console and locks a table in production.

This skill covers the storage decision. `design-code-change` holds the ranking that
decides between options, and `write-technical-report` holds how the proposal reads.

## Voice and register

Table, column, index, and constraint names read like speech rather than a
design document, and so does the prose around them.

- Name the thing, not one instance of it, and keep to one possessive at most.
- Use the plain verb, not one picked for flavor where a plain one exists.
- Say what happens, not the machinery behind it. Cut a trailing clause that
  re-derives the mechanism.
- No personification, judgment adverbs, rhetorical construction, conversational
  filler, or em dashes.
- American English: `color`, `behavior`, `canceled`, `analyze`, `license`, `defense`,
  never the British spelling. Three things keep their own spelling: an existing
  identifier, API name, string literal, or quoted text, copied exactly as it is; a new
  name joining a family the repository already spells the British way; and anything a
  standard, schema, or protocol fixes. Prose is American English everywhere.

**The read-aloud test.** Say a comment, a title, a description, or a report sentence to
a teammate at your desk. Rewrite anything nobody would say.

**Identifiers take the words, not the sentence.** A symbol, table, column, branch,
metric, span, or attribute name uses the plain words these rules produce and stops
there. Its shape comes from the repository's convention first, then from the standard
the name belongs to. Never reword a name that a standard, a framework, or a tool
fixes.

## Start from the access patterns

Write the access patterns before writing a single `CREATE TABLE`. A table designed
without them is a guess.

For each read and write the feature needs, record:

- what triggers it (a page load, a drag, a webhook, a background job)
- the filter columns, the sort columns, and whether it pages
- how many rows it touches now and at 100x
- how often it runs, and its latency budget
- whether it runs inside a transaction with anything else

> ✅
>
> | Pattern | Trigger | Filter | Sort | Rows | Frequency |
> | --- | --- | --- | --- | --- | --- |
> | Load a board | Page view | `view_id` | `position` | 1 config, ~20 columns | Per page view |
> | Page a column | Scroll | `view_id`, `column_id` | `rank`, `id` | 50 per page | Per column, per view |
> | Move a card | Drag | `card_id` | none | 1 | High during editing |

Two rules follow:

- **The write patterns matter as much as the reads.** A shape that makes one read fast by
  making every write rewrite a thousand rows is not a win.
- **A pattern with no index and no stated reason is an unfinished design.** Every row in
  the table above maps to an index, or to a full scan you name and accept because the
  table is bounded and small.

## Put invariants in the database

If a rule must always hold, the database enforces it. Application checks run outside the
transaction boundary that would make them true, so two concurrent requests both pass the
check and both write.

| Rule | What enforces it |
| --- | --- |
| This value is required | `NOT NULL` |
| No two rows share this value | `UNIQUE` constraint, scoped to the tenant or parent |
| This points at a real row | Foreign key, with `ON DELETE` chosen deliberately |
| This value is in a set or a range | `CHECK`, an enum type, or a lookup table with a foreign key |
| Exactly one row is the default | Partial unique index, or a pointer column on the parent |
| Two rows cannot overlap | Exclusion constraint, or a unique key on the discretized range |

> ❌ `validate :only_one_primary_column` in the model, checked with a `SELECT` before
> insert. Two concurrent inserts both read zero and both write.
>
> ✅ `CREATE UNIQUE INDEX ON board_columns (view_id) WHERE is_primary;` The second insert
> fails with a constraint violation the caller handles.

Choose `ON DELETE` rather than accepting the default. `CASCADE` when the child cannot
exist alone, `RESTRICT` when deletion should be refused, `SET NULL` only when the column
is genuinely optional. Deleting a parent must never leave rows pointing at nothing.

## Index design

An index is a data structure with a shape, not a switch you turn on.

- **Composite column order is equality, then sort, then range.** A query filtering
  `view_id = ?` and `column_id = ?`, sorting by `rank`, wants
  `(view_id, column_id, rank)`. Putting `rank` first makes the index useless for the
  filter.
- **A prefix of an existing composite index needs no index of its own.**
  `(view_id, column_id, rank)` already serves lookups on `view_id` alone, and on
  `view_id, column_id`. An extra index on `view_id` is write cost for nothing.
- **Sorts and ranges must be the last column used.** Once the scan hits a range or a sort,
  columns after it in the index cannot filter.
- **Cover the query when the payload is small and the read is hot.** Adding the two
  selected columns to the index avoids the row lookups. Do not do this to a wide row or a
  column that changes often.
- **Selectivity decides whether the index is used at all.** An index on a boolean or a
  two-value status column is usually ignored. A partial index (`WHERE archived_at IS
  NULL`) on the rows actually queried is the version that works.
- **Every index costs write throughput and space.** It is maintained on every insert,
  update to its columns, and delete. Adding six indexes to a hot write table is a
  decision, not a precaution.
- **The unique index is the constraint.** Do not add a separate non-unique index on the
  same leading columns.
- **A function or a cast on the column disables the index.** `WHERE lower(email) = ?`
  needs an expression index on `lower(email)`, or a stored normalized column. A `varchar`
  column compared to an integer will not use its index either.

State the plan, not a hope: "one index seek returning 50 rows", not "this should be
fast". Where the repository has tooling to check it (`EXPLAIN`, a query analyzer, a
CI query-plan check), run it and quote the result.

## Choosing the shape

### Separate table, column, or JSON

- **A column** when the value is single, typed, and belongs to that row.
- **A separate table** when there can be more than one, when it has its own lifecycle,
  when it needs its own constraints, or when it is written far more often than the parent
  row.
- **JSON or a serialized blob** only for opaque data that is never filtered, sorted,
  joined, aggregated, or constrained, and that no other feature reads. The moment a
  product question asks "which boards group by assignee", the field needs to be a column.

> ❌ `views.board_config jsonb` holding grouping, column order, and card limits, because
> the shape might change.
>
> ✅ `board_configurations` with `group_by_field`, `swimlane_field`, and a foreign key to
> `views`. The grouping field is filterable and indexable, and the constraint set is real.

Denormalize only with a named reason and a named invalidation path. A counter cache, a
materialized view, or a duplicated column is a cache, and a cache with no invalidation
produces wrong answers rather than slow ones. Say what updates it, and what happens when
that update fails.

### Keys and identifiers

- Prefer a surrogate primary key. A natural key that is also user-visible data will need
  to change.
- Random UUIDs as a clustered primary key scatter writes across the index. Prefer a
  sequential id, or a time-ordered UUID (v7 or ULID), when insert rate matters.
- A public identifier and a primary key are different concerns. Do not expose a sequential
  key when it leaks volume or enables enumeration.
- In a multi-tenant table the tenant column belongs at the front of the primary key and of
  every secondary index, so that every query is scoped and every scan is bounded.

### Nullability and state

- `NULL` means "unknown or not applicable". Do not use a sentinel like `-1`, `""`, or the
  epoch to avoid a nullable column, and do not use `NULL` to mean a real state that
  belongs in an enum.
- Model a state machine as one column with a constrained set of values, not as a set of
  booleans that can contradict each other.
- Soft deletion changes every query and every unique constraint in the table. If rows are
  soft deleted, the unique indexes must be partial, and the default scope has to be
  explicit rather than remembered.
- Store timestamps in UTC with a time zone aware type, and store money in a minor-unit
  integer or a fixed-point decimal, never a float.

### Ordering and ranking

User-rearrangeable ordering is its own design problem, and the naive version is a
performance bug.

- **Contiguous integer positions** require updating every row after the insertion point on
  each move, and two concurrent moves interleave into a duplicated or skipped position.
  Acceptable only for small, bounded, single-writer lists.
- **Sparse integers** (gaps of 1000) reduce the rewriting but still need a periodic
  renumbering pass, which has to be safe against concurrent moves.
- **Fractional or lexicographic ranks** (a fractional index, or a Lexorank-style string)
  make a move a single-row update. They need a deterministic tie-break, a maximum key
  length or precision policy, and a rebalance path.

Whichever is chosen, name the tie-break. `ORDER BY rank` with duplicate ranks is a
non-deterministic order, and pagination on a non-deterministic order drops and repeats
rows. `ORDER BY rank, id` is stable.

Page with a keyset (`WHERE (rank, id) > (?, ?)`) rather than `OFFSET` on anything a user
can scroll deeply. `OFFSET 10000` reads and discards ten thousand rows.

## Migration and rollout safety

A schema change is a deploy, and the old code runs against the new schema and the new code
against the old one. Design for both.

Expand, then contract, one deploy per step:

1. **Add** the new column, table, or index. Nullable, with no default that rewrites the
   table, and no code reading it yet.
2. **Backfill** in batches, in its own job, resumable, with the write path already writing
   both old and new.
3. **Switch reads** to the new column, behind a flag if the read is risky.
4. **Stop writing** the old column.
5. **Drop** it, in a later deploy, once nothing reads it and a rollback would not need it.

Hazards to check before proposing the migration:

- **Locks.** Adding an index without `CONCURRENTLY` (Postgres) or an online algorithm
  (MySQL) blocks writes for the duration. Check what the repository's migration tooling
  does by default.
- **Table rewrites.** Adding a `NOT NULL` column with a volatile default, changing a
  column type, or narrowing a column can rewrite the whole table.
- **Long transactions.** A migration that runs inside one transaction on a large table
  holds locks until it finishes. Batch it.
- **Validation separately from the constraint.** Add the foreign key or check constraint
  as `NOT VALID`, then validate it in a second step, where the tooling supports it.
- **Reversibility.** Every step up to the drop must be reversible without data loss. Say
  which step is the point of no return.
- **Existing rows.** A new constraint has to be true of the data already in the table. Say
  what happens to rows that violate it, before the constraint is added.

Never write, backfill, or delete existing persisted data without asking first.

## Follow the repository

Read the adjacent tables before designing new ones. Match the repository's naming, key
strategy, timestamp columns, soft-delete convention, enum handling, and migration
tooling, even where a different convention would be better. Where the repository's
convention is worse but still correct here, follow it, say so, and describe the better
pattern in one or two sentences so the user can decide separately.

Where the repository's convention would make this case incorrect (a missing tenant scope,
a unique constraint that does not hold), correctness wins. Fix it for this case and say
so rather than copying the defect.

## What to ask

Schema work is on the always-ask list. Ask before proposing a final design, in one
message, with a default for each question:

- Expected row counts and growth for each new table, and the read and write rates.
- Whether an existing column or table is already read by another system, a report, or an
  external consumer.
- Whether the data is tenant-scoped, and what the tenant boundary is.
- Retention, deletion, and whether any of it is user data subject to a deletion request.
- Which database and version, and what the repository's migration tooling allows online.
- Whether a proposed change has to be backward compatible with a release already
  deployed.

Do not ask what reading the repository or the linked schema would answer.

## Anti-patterns

| Anti-pattern | The tell | Instead |
| --- | --- | --- |
| Entity-attribute-value | A `key`/`value` table standing in for columns | Real columns, or a JSON column if genuinely opaque |
| Index shotgun | An index per column, added to make something fast | Indexes derived from the access pattern table |
| JSON as a schema | Filtering or sorting inside a JSON column | Promote the queried fields to columns |
| Invariant in the app | A `SELECT` then an `INSERT` to enforce uniqueness | A unique constraint |
| Nullable everything | Every column nullable so the migration is easy | `NOT NULL` where the value is required |
| Comma-separated list | Ids joined into a string column | A join table |
| `OFFSET` pagination | Deep paging on a user-scrollable list | Keyset pagination on a stable sort |
| Boolean state set | `is_active`, `is_archived`, `is_draft` on one row | One status column with a constrained set |
| Reordering by renumber | An `UPDATE ... SET position = position + 1` on move | A rank column with single-row moves |
| One-shot migration | Add, backfill, and read in a single deploy | Expand, backfill, switch, contract |

## Workflow

1. **Read the existing schema.** The tables this joins to, their keys, their indexes, and
   the conventions they follow. Read any linked design document, and note that it may be
   stale.
2. **Write the access pattern table.** Reads and writes, with filters, sorts, volumes, and
   frequency.
3. **Ask the blocking questions,** in one message, each with a default.
4. **Model the entities and the invariants,** and decide what each constraint is.
5. **Derive the indexes from the access patterns,** and check each pattern against the
   index list.
6. **Walk the correctness checks** in `design-code-change`: concurrency, partial failure,
   ordering, data integrity, and behavior at scale.
7. **Plan the migration** as expand, backfill, switch, contract, and name the locks and
   the point of no return.
8. **Write it up** with `write-technical-report`: recommendation first, schema in code
   blocks, access patterns and indexes in a table, rejected alternatives with reasons, and
   numbered open questions.

## Before you finish (checklist)

- [ ] Everything written passes the read-aloud test: a sentence a teammate would
      say, not one lifted from a design document. Nothing narrates one
      hypothetical instance, chains possessives, picks a verb for flavor where a
      plain one exists, or re-derives the mechanism in a trailing clause.
- [ ] American English in all prose. Spelling is preserved only in a quoted
      identifier, API name, string literal, or quoted text, in a new name joining a
      family the repository already spells the British way, and where a standard,
      schema, or protocol fixes it.
- [ ] The access patterns are written down, with filters, sorts, volumes, and frequency.
- [ ] Every access pattern maps to an index, or to a stated and accepted full scan.
- [ ] Composite index column order is equality, then sort, then range, and no index
      duplicates the prefix of another.
- [ ] Every invariant is a database constraint, not an application check.
- [ ] Every foreign key has a deliberate `ON DELETE` behavior.
- [ ] Nothing that is filtered, sorted, joined, or constrained lives in a JSON column.
- [ ] Any denormalized or cached value names what updates it and what happens when that
      fails.
- [ ] Ordering has a stable tie-break, and rearranging does not rewrite the list.
- [ ] Deep pagination uses a keyset, not `OFFSET`.
- [ ] Tenant scoping is at the front of the primary key and of every secondary index.
- [ ] The migration is expand, backfill, switch, contract, with locks, table rewrites, and
      the point of no return named.
- [ ] Every step is reversible up to the stated point of no return.
- [ ] The design matches the repository's conventions, or the deviation is stated with its
      reason.
- [ ] Schema changes and data writes were approved before being made.
