---
name: write-code-comments
description: >
  Use this skill whenever writing, adding, reviewing, trimming, or rewriting
  comments, docstrings, JSDoc, TSDoc, rustdoc, godoc, or any API documentation in
  code (for example "add a comment explaining this", "document this function",
  "write a docstring", "clean up these comments", "why is this commented"). It
  also applies with no prompting during any code change, since every new comment
  is written under these rules. It produces short comments that record what the
  code cannot express, and keeps narration, process history, and self-defense out
  of the source.
---

# Code Comment Writing

Write a comment only when it records something the code cannot express: an
external constraint, a hidden invariant, a non-local hazard, a workaround, a
required local exception, or a public contract. Remove narration, process
history, and anything already visible in the code.

This is the failure to prevent, nine lines on a one-line constant:

```js
/**
 * A handler that does nothing with the move it is told about, which is all it takes to
 * make a board a drag surface.
 *
 * `Playground` states no `onItemsMove`, and a board without one drags nothing at all: no
 * card is a drag source and no cell is a drop target, so there is no held card for the
 * auto-scroll below to answer. Supplied here rather than added to the story, because what
 * these tests need is a board that drags and the story is deliberately the one that wires
 * no callbacks.
 */
const MOVES_NOWHERE = () => {}
```

It translates `() => {}` into English, restates what the story file already
shows, spells out what would happen if the line were absent, and defends a
placement nobody questioned. One line covers it:

```js
// The board only drags when onItemsMove is set.
const MOVES_NOWHERE = () => {}
```

## The one-purpose test

Name an explanatory comment's purpose from this list before writing it.
Explanatory prose whose purpose is not on the list gets deleted. Required legal
and license notices, generated-file markers, compiler and tool directives
(`//go:build`, source-map pragmas, coverage and formatter controls),
repository-mandated comments, and tracked `TODO:` comments follow their own rules
and are exempt from this test.

| Purpose | Example |
| --- | --- |
| External constraint the reader cannot see from here | `// Safari fires pointercancel when scrolling starts; treat it as a drop.` |
| Invariant or ordering the types cannot express | `// Must precede flush(), which reads this buffer.` |
| Non-local hazard, where a change here breaks something distant or silent | `// Changing this key orphans every persisted draft.` |
| Magic value with an external source | `// 512 KB, the gateway's request body limit.` |
| Dense encoding: what a regex, bitmask, or formula computes | `// Matches ISO 8601 dates with an optional timezone offset.` |
| Workaround, with its removal trigger | `// Works around https://github.com/facebook/react/issues/24304 until React 19 is the minimum supported version.` |
| Rejected alternative a reader would otherwise try | `// A Set is slower here: these arrays are under 8 items and this runs per frame.` |
| Required local exception a maintainer would otherwise normalize away | `// The vendor client returns a new connect each render; listing connect in deps causes a reconnect loop.` |
| Public API contract | See [API documentation](#api-documentation). |

Keep the minimum facts that make the purpose actionable. A comment may carry its
cause, its consequence, its scope, or its removal trigger when the purpose is not
actionable without them. Drop every fact that serves a different purpose, however
true or interesting.

Then delete the comment anyway if any of these holds:

1. **The name says it.** `MOVES_NOWHERE` already says the function moves nothing.
   Rename instead of commenting.
2. **The signature or type says it.** `(user: User) => Promise<void>` says what
   goes in and that it is async.
3. **The language says it.** `() => {}` does nothing. `??=` assigns when nullish.
   Assume a competent reader of this language and its standard library.
4. **Code within a few lines says it,** including the test name, the assertion,
   and the adjacent call site.

## Budget

| Comment on | Limit |
| --- | --- |
| A declaration, assignment, or call | 1 line |
| A block, branch, or function body | 2 lines |
| A dense encoding, formula, or externally mandated rule | 3 lines |
| Anything else | 3 lines |

- **Prefer a comment shorter than the code it sits on, but line count is not a
  hard cap.** A one-line expression encoding a protocol rule or a legally
  mandated calculation may need the full three lines, and no rename or extraction
  can encode an external obligation.
- **No second paragraph in an implementation comment.** Extended design
  discussion belongs in a doc, an ADR, or the pull request. API documentation is
  exempt.
- **Improve the code when an in-scope rename or extraction removes the need for
  the comment.** Do not refactor only to shorten a comment.
- An implementation comment may exceed three lines only where repository-required
  syntax or a mandated notice requires it. Report every such exception.

## Patterns to reject

Check named phrases literally. Evaluate restatement, inverse narration, process
defense, personification, and session residue against the surrounding code and
the task history.

**1. Restating the code.** The sentence stays true with the code deleted and only
the name left.

> ❌ `// Loop over the users and add each total to the sum.`
>
> ✅ Delete it.

**2. Explaining the language or a standard idiom.**

> ❌ `// An empty arrow function, so calling it does nothing.`
>
> ✅ Delete it.

**3. Narrating the inverse.** Do not spell out the obvious inverse of the code. A
counterfactual is allowed only when it supplies the consequence an allowlisted
purpose needs to be actionable. Name the concrete failure and the symbol or data
it affects.

> ❌ `// If this were not sorted, the binary search below would not work, and
> lookups would return wrong results for anything past the first element.`
>
> ✅ `// findSlot requires sorted input.`
>
> ✅ `// Await persistReplacement() before cleanup(); cleanup() can delete replacementPath before fsync() completes.`

**4. Process defense.** Why a file was chosen, what a reviewer questioned, how
the implementation was reached. A durable local constraint is different: state it
beside the code, and leave the debate in the pull request.

> ❌ `// Defined here rather than in the shared helpers, because what these tests
> need is a fixture that changes with them.`
>
> ✅ Delete it.

**5. Ornamental construction.** Contrast or cadence that adds emphasis without
information. Named forms: `not X, but Y`; `which is all it takes`; repeated
parallel clauses; a closing aphorism. Colons, semicolons, and negation are fine
when they are the shortest clear way to state the reason.

> ❌ `// Not a cache, but a promise: the value is never stored, only the work that
> produces it.`
>
> ✅ `// Holds the in-flight promise so concurrent callers share one request.`

> ❌ `// A single retry, which is all it takes to survive the gateway's cold start.`
>
> ✅ `// One retry covers the gateway's cold start.`

**6. Personification.** Verbs of behavior are fine: the parser rejects, the queue
drops the oldest entry. Verbs of intent or feeling are not: knows, wants, cares,
decides, believes, refuses, answers, is happy to.

> ❌ `// The reducer does not care about drag state, so it happily ignores it.`
>
> ✅ `// Drag state lives in DragProvider.`

**7. Judgment adverbs.** deliberately, intentionally, on purpose, by design,
carefully, properly, simply, obviously, of course, note that, importantly,
essentially, actually. `deliberately` asserts intent the reader cannot verify,
and its synonyms are the same claim in different words. Where a reader might
mistake the code for a bug, say what breaks if they "fix" it.

> ❌ `// The retry count is deliberately 1.`
>
> ✅ `// One retry only: the endpoint is not idempotent.`

**8. Session residue.** Anything meaningful only to someone who watched the work
happen: what a test needed, what came up, what was tried.

> ❌ `// Added because the auto-scroll test needed a board that drags.`
>
> ✅ Delete it.

**9. Positional references.** `below`, `above`, `the block that follows`. They
break on the first reorder. Name the symbol.

> ❌ `// Must run before the effect below.`
>
> ✅ `// Must run before useBoardLayout, which reads this ref.`

**10. Restatement and preamble.** `In other words`, `Put differently`,
`Essentially`, and context placed ahead of the fact. Lead with the fact, once.

> ❌ `// The board supports three view modes. Of these, only grouped mode has
> swimlanes. This check guards against a swimlane lookup in the other two.`
>
> ✅ `// Only grouped mode has swimlanes.`

## Voice

- Use present tense. Indicative is the default; imperative or `must` is allowed
  for a required action, an ordering constraint, or a removal trigger. Do not
  describe how the code "was changed to", "has been made", or "will eventually"
  behave.
- No "I" or "we". No em dashes. No emoji.
- No decorative metaphor or imagery. Conventional technical verbs are fine where
  they name an established code relationship directly.
- Name real symbols instead of describing them in prose.
- Follow the file's existing capitalization and punctuation convention. Its
  comment density is not a reason to add another comment.

## Context

- **Drift.** State stable constraints, not the current sequence of implementation
  steps. Where the constraint is testable, add the test as well as the comment.
  When you change code, check the comments around it, not only the ones you
  edited, and update or delete any your change made inaccurate.
- **Tests.** Prefer test names, fixture names, and assertions. Comment only
  hidden harness behavior, non-obvious setup ordering, or an external issue or
  specification that will not fit the test name. Never explain what a fixture
  visibly does.
- **Generated files.** Do not add or edit comments in generated output. Change
  the generator, template, or schema. Preserve generated-file markers.
- **Config and build files.** Comment a stanza-level constraint, unit, or
  compatibility requirement. Do not narrate each YAML key, Dockerfile
  instruction, or shell line.
- **Existing docs and ADRs.** State the local constraint and link the canonical
  source. Do not copy its rationale or history into the code.
- **Suppression directives.** Use the narrowest scope and name the exact
  constraint that makes the rule inapplicable. `design-code-change` requires a
  local comment for lint disables and untyped boundaries. Other
  legitimate-looking anti-patterns must be justified in a comment or in the
  report, as that skill specifies.

## API documentation

Public API documentation has the fixed purpose of recording the caller-visible
contract. The implementation delete checks and the length budget do not apply.

- Document behavior, parameters, return value, thrown errors, side effects, input
  constraints, and any concurrency or lifecycle requirement.
- Use the language's required convention: TSDoc or JSDoc tags, the repository's
  docstring format, rustdoc, godoc's `Name ...` opening.
- **Do not paraphrase the signature.** `@param userId The user ID` adds no
  contract information. Document what the parameter constrains, or omit the tag.
- Skip short private helpers with self-describing names.
- Multiple sentences and paragraphs are allowed where the contract needs them.
  The Voice rules and patterns 2 and 4 through 10 still apply. Document
  caller-visible behavior even when the implementation is obvious.

> ❌
> ```ts
> /**
>  * Gets the user.
>  * @param id The id
>  * @returns The user
>  */
> ```
>
> ✅
> ```ts
> /**
>  * Loads a user by id, from cache when the entry is under 30 seconds old.
>  *
>  * Returns `null` when no user exists. Throws `AuthError` when the caller lacks
>  * read access.
>  */
> ```

## Rewrites

Hard cases, over budget and in budget.

**A coupled invariant.** Two clauses, one purpose. The second clause is the
reason the first is enforceable, so it stays.

> ❌ `// It is important that both of these happen together. If the token is
> verified in one transaction and the nonce consumed in another, then an attacker
> who captures the request can send it a second time in the window between them,
> and the second request will pass verification because the nonce is still
> unconsumed.`
>
> ✅ `// Verify the token and consume the nonce in one transaction; separating them permits replay.`

**A required suppression.** A local exception a maintainer would otherwise remove.

> ❌ `// eslint-disable-next-line react-hooks/exhaustive-deps` with no comment, or
> with `// The linter is wrong here.`
>
> ✅
> ```ts
> // The vendor client returns a new connect each render; listing connect in deps causes a reconnect loop.
> // eslint-disable-next-line react-hooks/exhaustive-deps
> ```

**An ordering requirement.**

> ❌ `// Important: this line needs to come first. If you move it after the
> subscription is set up, the initial value gets missed, because the subscription
> only fires on subsequent changes and not on the current one.`
>
> ✅ `// Read before subscribing: subscribe() only fires on later changes.`

**A deviation from the obvious implementation.**

> ❌ `// We use a plain object here instead of a Map. Maps are usually the better
> choice for this kind of lookup, and normally that is what you would reach for,
> but in this particular case the keys are all strings and the object is
> serialized directly into the response, so a Map would need converting back.`
>
> ✅ `// serializeResponse cannot encode Map values.`

## Workflow

1. **Fix the code first.** A rename, an extracted function, or a named constant
   beats a comment when it fits the scope you were given.
2. **Name the purpose** from the one-purpose list. Not on the list means no
   comment.
3. **Run the four delete checks:** name, signature, language, nearby code.
4. **Write it,** leading with the fact and keeping only the facts the purpose
   needs to be actionable.
5. **Check the draft against the ten patterns** literally, then against the
   budget.
6. **Sweep the change** for comments it made inaccurate, including ones you did
   not edit.
7. **Report** every implementation comment over three lines, and the repository
   requirement or mandated notice that required it.

## Before you finish (checklist)

- [ ] Every explanatory comment's purpose is on the one-purpose list; required
      notices, directives, and tracked `TODO:` comments are exempt.
- [ ] No comment carries a fact serving a different purpose.
- [ ] No implementation comment exceeds three lines or has a second paragraph,
      unless repository-required syntax or a mandated notice requires it, and
      every exception is reported.
- [ ] No comment restates the name, the signature, the language, or nearby code.
- [ ] No counterfactual unless it makes an allowlisted purpose actionable and
      names the concrete failure and the affected symbol or data.
- [ ] No process defense: no file-choice rationale, reviewer history, or session
      residue.
- [ ] No `not X, but Y`, `which is all it takes`, parallel clauses, or closing
      aphorism.
- [ ] No personification, no judgment adverbs, no "deliberately" or "on purpose".
- [ ] No `below`, `above`, or other positional reference; symbols are named.
- [ ] Every workaround names its issue and its removal trigger.
- [ ] Every suppression directive names the constraint that makes the rule
      inapplicable.
- [ ] Public API documents the contract without paraphrasing the signature.
- [ ] Comments made inaccurate by this change are updated or deleted.
- [ ] No commented-out code, changelog comments, author bylines, or divider
      banners. Legal, license, and generated-file notices preserved.
- [ ] Any `TODO:` names a specific action and a complete tracking-issue URL.
