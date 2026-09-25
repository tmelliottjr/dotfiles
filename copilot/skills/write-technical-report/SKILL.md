---
name: write-technical-report
description: >
  Use this skill whenever the deliverable is a written technical document rather
  than code: a design or schema proposal, an architecture or data model writeup,
  an options comparison, an investigation or root cause analysis, a
  recommendation, or a findings summary, whether it is answered in the session or
  saved as a Markdown doc (for example "put together the proposed schema", "write
  up the analysis", "document the access patterns", "what are our options",
  "summarize what you found", "explain how this works"). It also applies with no
  prompting to the summary at the end of every task, since that is where the same
  prose comes back. It states the conclusion first, and keeps decision
  changelogs, personification, hedging, and conversational padding out of the
  document.
---

# Technical Reports and Analysis

A technical document reports the conclusion, not the trip taken to reach it. The
reader wants the recommendation, the reasons it wins, and the things that are
still unknown.

The failure this skill exists to prevent is a writeup that reads as a transcript:
a narrated changelog of what was considered and discarded, systems described as
if they had intentions, and paragraphs of conversation wrapped around a small
amount of information. The same rules that keep this out of a pull request
description, an issue, and a code comment apply here.

## Voice and register

Write it the way you would say it. The common failure is a literary register that
is grammatical, accurate, and nothing anyone would say out loud, copied from the
voice of a design document.

Four rules catch nearly all of it:

1. **Name the thing, not one instance of it.** "A board's no value bucket" and "a
   parent conditional access refuses" narrate one hypothetical example. Name it in
   general terms, plural where that reads naturally: "empty buckets", "refused
   parents". Keep "the" only when it points at one specific real thing.
2. **One possessive at most.** No `'s` chains and no "its". Two links of possession
   describe a data relationship, not a sentence. Name the symbols instead.
3. **Use the plain verb.** `add`, `remove`, `fix`, `use`, `show`, `hide`, `read`,
   `write`, `return`, `call`, `skip`, `fail`, `load`, `check`. Not a verb picked for
   flavor where a plain one exists: `draw`, `carry`, `reach`, `surface`, `honor`,
   `teach`, `compose`, `enumerate`, `bound`, `spell`.
4. **Say what happens, not the machinery behind it.** A trailing clause that
   re-derives the mechanism is the tell: "after its X", "per Y", "on its Z", "is
   left out of the items the page builds". Cut it and check whether the line still
   says enough. It normally says more.

**The read-aloud test.** Say a comment, a title, a description, or a report sentence
to a teammate at your desk. Say a pull request title as "I ___", a commit message as
"this commit ___", and a test name after "this checks that". Rewrite anything nobody
would say. This is about register, not length; a line can be accurate, specific, and
within budget and still fail.

**Identifiers take the words, not the sentence.** A symbol, table, column, branch,
metric, span, or attribute name uses the plain words the four rules produce and stops
there. Its shape comes from the repository's convention first, then from the standard
the name belongs to. Never reword a name that a standard, a framework, or a tool
fixes.

**American English.** Write `color`, `behavior`, `canceled`, `flavor`, `analyze`,
`organize`, `license`, `defense`, `catalog`, `gray`, never the British spelling. Three
things keep their own spelling: an existing identifier, API name, string literal, or
quoted text, copied exactly as it is; a new name joining a family the repository
already spells the British way; and anything a standard, schema, or protocol fixes.
Prose is American English everywhere.

These rules hold for every kind of writing.

## Style rules (always apply)

- **Lead with the conclusion.** The recommendation, the answer, or the finding
  goes in the first two sentences. Background, alternatives, and supporting
  detail come after. Never save the answer for the end.

  > ❌ To understand the board layout question, it helps to start with how views
  > currently store configuration. The `views` table has a `filter` column added
  > last quarter, and the new schema builds on that. With that context in place,
  > we can look at where board layout might live.
  >
  > ✅ Board layout belongs in a separate `board_configurations` table keyed by
  > `view_id`, one row per view. The rest of this covers why a column on `views`
  > does not work and what indexes the read path needs.

- **No changelog of the work.** The document describes the design as it stands.
  Cut what was tried first, what was reconsidered, what a review turned up, which
  files were read, and how many attempts it took.

  > ❌ I initially modeled the layout as a JSON blob on `views`. After digging
  > into the query patterns I realized grouping needs to be filterable, so I
  > revisited that and moved to a separate table.
  >
  > ✅ Layout lives in its own table. A JSON column on `views` cannot serve the
  > "all boards grouped by assignee" query, which needs an indexed equality
  > match on the grouping field.

  A rejected alternative belongs in the document when the reader would otherwise
  propose it. State it as a rejected option with the reason, not as a step in a
  story.

- **Break every enumeration out of the sentence.** Two or more options,
  constraints, access patterns, or affected areas become bullets under a one-line
  lead-in ending in a colon. Do not run them inline behind "and". Bullets stay
  fragments: one line each, one level deep, no trailing periods.

  > ❌ The read path needs to fetch the board by view, list its columns in order,
  > and page through the cards in each column, and it also has to handle the
  > case where a column has been deleted.
  >
  > ✅
  >
  > > The read path has four access patterns:
  > >
  > > - fetch a board by `view_id`
  > > - list columns in display order
  > > - page cards within a column
  > > - resolve cards whose column no longer exists

- **No personification.** A table, service, query, or type does not know, want,
  care, refuse, decide, or happily do anything. Say what the code or the data
  does.

  > ❌ The `views` table has no idea what a board is, so it happily accepts a
  > layout it cannot validate.
  >
  > ✅ `views` has no constraint on the layout column, so an invalid grouping
  > field is stored without error.

- **No conversational phrases.** Drop openers, transitions, and sign-offs such as
  "Great question", "Let's dig in", "Now, here's the interesting part", "Hope
  this helps", "Let me know what you think".

- **No hedging.** "Might", "possibly", "arguably", "it could be worth
  considering", and "I could be wrong" weaken a claim without adding information.
  State the claim, or move it to Open questions as a question.

  > ❌ It might be worth possibly considering an index here, though I could be
  > wrong about the volume.
  >
  > ✅ `(view_id, position)` needs a composite index. Ordering a 5,000-card board
  > without it is a full scan of `board_items`.

- **No rhetorical construction.** No reversals ("not just X, it is Y"), no
  repeated parallel clauses, no closing line built to land. State it flat.

  > ❌ This is not merely a schema change, it is a rethinking of how ordering
  > works.
  >
  > ✅ Ordering moves from the client to a persisted rank column.

- **No judgment adverbs and no self-congratulation.** Drop "simply", "obviously",
  "clearly", "elegant", "clean", "robust". Describe the property instead: "one
  query instead of one per column", not "much cleaner".

- **Plain language, technical where precision matters.** Use real table, column,
  file, and system names. No metaphor, no analogy that the reader has to unpack,
  no bolded thesis paragraph.

- **No em dashes.** Use commas, parentheses, or separate sentences.

- **No time or effort estimates.** Do not size the work in hours, days, sprints,
  or t-shirt sizes. Describe scope in terms of what changes.

- **Every claim carries its evidence.** A number, a file path with a full
  `https://github.com/...` link, a query plan, a constraint, or a named
  precedent. Do not assert a performance property without the reason it holds.
  Never invent a table, column, or figure to fill a gap; ask instead.

- **Name what is unverified.** Anything assumed, unread, or taken from a document
  that may be stale gets said in one line, near the claim that rests on it.

## Length budgets

Say it once, at the length the content needs, then stop.

- No paragraph over three sentences. Most are one or two.
- No section that restates another. A summary plus a body that repeats it is one
  section too many.
- Use a table when options are compared on more than two dimensions. Use prose
  for a single recommendation.
- Schema, code, and query blocks are exempt from the budgets. The prose around
  them is not.
- If the answer is two sentences, the document is two sentences. Do not pad it to
  look thorough.

## Default structure

Pick the shape that fits and drop any section with nothing useful in it. These
are defaults, not a template to fill in.

### Proposal or design analysis

```markdown
## Recommendation
The proposed design in two or three sentences.

## Schema (or Design)
Tables, columns, types, and constraints. Code blocks, not prose.

## Access patterns and indexes
| Access pattern | Query shape | Index |

## Rejected alternatives
- **<Name of the option>.** Why it does not win, in one or two sentences.

## Risks and migration
- What breaks, what needs backfilling, what has to ship first.

## Open questions
1. The question, with the default you will take if there is no answer.
```

### Investigation or findings

```markdown
## Finding
What is true, in one or two sentences.

## Evidence
- The observation, with the file, link, query, or measurement behind it.

## Cause
Where the problem originates, and why it produces the symptom.

## Options
Two or three, each with what it costs and what it buys, then a recommendation.

## Unverified
- What could not be confirmed, and what it would take to confirm it.
```

### End-of-task report

The summary at the end of a task is a technical report and follows every rule
above. Report what changed, what was verified, where the repository's conventions
differed from the request, anything that turned out to be wrong or already
solved, and any decision made while unsure, one line each. Do not narrate the
sequence of edits, and do not list the tools used.

## Recommendations and open questions

- **Recommend, do not hand back a menu.** "Recommend X because Y" is a sentence.
  A neutral list of options with no pick is an unfinished document.
- **Rank by correctness, then precedent, then performance.** Implementation cost
  is disclosed as a tradeoff, never used as the reason. The `design-code-change`
  skill holds the full ranking and the correctness checks; this skill governs how
  the result reads.
- **Ask real questions in one place.** Collect them at the end, numbered, each
  with the default you will take if the user does not answer. Do not scatter them
  through the prose as hedges.
- **A question is for something only the user knows.** Roadmap, traffic shape,
  data volume, who else reads the table, whether a column is already in use. Do
  not ask what reading the repository would answer.

## What this skill does not cover

- **The decision itself.** Use `design-code-change` for ranking options and
  walking the correctness checks. This skill is the writeup.
- **Pull request descriptions and issues.** Use `write-pull-request` and
  `write-github-issue`; they have their own structures and templates.
- **Comments and API docs in source files.** Use `write-code-comments`.
- **Blog posts, discussions, and vault research notes.** Use
  `blog-discussion-post` or `obsidian-research`.

## Workflow

1. **Confirm the deliverable and the reader.** A schema proposal for a reviewer
   and a root cause summary for the user are different documents.
2. **Gather the evidence first.** Read the code, the schema, the linked
   documents. Note anything you could not verify rather than filling the gap.
3. **Ask blocking questions before writing,** in one message, each with a
   default. Do not write a document built on a guess you could have resolved.
4. **Write the conclusion first,** then the support, then the rejected options,
   then the open questions.
5. **Cut the narration.** Reread for "I started", "initially", "then I", "after
   reconsidering", and delete those sentences. The design stands on its own.
6. **Check the budgets** and delete any section that repeats another.

## Before you finish (checklist)

- [ ] Everything written passes the read-aloud test: a sentence a teammate would
      say, not one lifted from a design document. Nothing narrates one
      hypothetical instance, chains possessives, picks a verb for flavor where a
      plain one exists, or re-derives the mechanism in a trailing clause.
- [ ] American English in all prose. Spelling is preserved only in a quoted
      identifier, API name, string literal, or quoted text, in a new name joining a
      family the repository already spells the British way, and where a standard,
      schema, or protocol fixes it.
- [ ] The conclusion is in the first two sentences.
- [ ] No changelog of the work: no attempts, no reconsiderations, no tools used,
      no files read.
- [ ] Rejected options appear as rejected options with reasons, not as steps in a
      story.
- [ ] No personification, no judgment adverbs, no self-congratulation.
- [ ] No conversational openers, transitions, or sign-offs.
- [ ] No hedging; uncertainty is a numbered open question with a default.
- [ ] No rhetorical construction and no em dashes.
- [ ] Every enumeration of two or more items is a bulleted list or a table.
- [ ] No paragraph over three sentences, and no section restating another.
- [ ] Every claim has evidence, with full `https://github.com/...` links, and
      nothing is invented.
- [ ] Anything unverified or assumed is named.
- [ ] There is a recommendation, not a neutral menu.
- [ ] No time or effort estimates.
