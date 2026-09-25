---
name: write-github-issue
description: >
  Use this skill whenever the user asks to write, draft, create, open, file, or
  log a GitHub issue, bug, task, or ticket (for example "write a GitHub issue",
  "open an issue for this", "file a bug", "draft a ticket", "log a task"). It
  produces concise, to-the-point issues that state the problem and the desired
  outcome without prescribing implementation details, then files them with the
  GitHub CLI on request.
---

# GitHub Issue Writing

Write GitHub issues that are short, specific, and easy to act on. State the
problem or goal and what "done" looks like, then stop.

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

- **Concise and to the point.** Every line earns its place. Prefer tight bullets
  over paragraphs.
- **Break every enumeration out of the sentence.** Two or more symptoms,
  conditions, affected areas, or outcomes become bullets under a one-line lead-in
  ending in a colon. Do not run them inline behind "and" or behind a colon.
  Bullets stay fragments: no repeated lead-in words, no trailing periods, one
  line each, one level deep.

  > ❌ Uploads fail for files over 100 MB, for files with non-ASCII names, and
  > when the session token has expired.
  >
  > ✅
  >
  > > Uploads fail in three cases:
  > >
  > > - files over 100 MB
  > > - non-ASCII file names
  > > - expired session token

- **What and why, not how.** Describe the problem or desired outcome. Do not
  prescribe specific implementation details, file names, function signatures, or
  a step-by-step solution. Leave the approach to whoever picks up the issue.
- **Plain language.** No jargon, no internal shorthand, no buzzwords. Write so
  someone new to the code can understand it.
- **No conversational phrases.** Drop openers and filler such as "Hey", "So
  basically", "I was thinking", "Could we maybe", "Just a quick one".
- **No rhetorical construction.** No reversals ("not X, but Y"), no closing
  clauses built to land. State the problem flat: "Login fails when the email
  contains a plus sign", not "The form accepts the address, but the lookup never
  finds it".
- **No personification and no judgment adverbs.** Code does not know, want, or
  care. Drop "deliberately", "simply", "obviously", "clearly".
- **No em dashes.** Use commas, parentheses, or separate sentences.
- **No lengthy explanations or elaboration.** If a section needs more than a few
  sentences, it is probably two issues.

## Default structure

Pick the shape that fits. Omit any section that has nothing useful to say.

### Task or feature

```markdown
## Problem
One or two sentences: what is missing or wrong, and why it matters.

## Outcome
- What is true when this is done (observable behavior or result).
- Keep each item focused on the result, not the implementation.

## Scope (optional)
- Anything explicitly out of scope.

## References (optional)
- Full https://github.com/... links, docs, or related issues.
```

### Bug

```markdown
## What happens
One or two sentences describing the actual behavior.

## Expected
One sentence describing the expected behavior.

## Steps to reproduce (if known)
1. ...
2. ...

## Context (optional)
- Version, environment, or links relevant to reproducing it.
```

## Title

- Short, specific, and plain. A noun phrase or an imperative works.
- Good: `Login fails when email contains a plus sign`.
- Avoid: vague titles (`Bug`, `Fix stuff`) and implementation details in the
  title.
- Do not add ticket prefixes or labels in the title unless the repository
  already does that.

## Workflow

1. **Check the repository.** Run `gh repo view` to confirm the target repo. Look
   for issue templates in `.github/ISSUE_TEMPLATE/` (or `.github/ISSUE_TEMPLATE.md`).
   If templates exist, follow their structure while keeping the style rules above.
2. **Gather only what is essential.** Ask a question only if the title or the
   desired outcome is genuinely unclear. Otherwise draft and note any assumption.
3. **Draft in Markdown** using the structure above. Show the draft to the user.
4. **Confirm before filing.** Do not create the issue until the user approves the
   draft.
5. **File it with the GitHub CLI** when asked:

   ```bash
   gh issue create --title "<title>" --body "<body>"
   ```

   Add `--label`, `--assignee`, `--milestone`, or `--repo` only when the user
   asks. Return the full `https://github.com/...` issue URL.

## Comments and replies

This skill files issues. It does not comment on them.

- **Do not comment on an issue, reply to a comment, react, assign, or `@` mention
  anyone.** This holds even when the answer seems useful to whoever is on the thread.
- **Reading is fine.** Fetch an issue and its comments for context with
  `gh issue view <number> --comments`.
- **A comment is not a substitute for filing.** When the content belongs on an
  existing issue rather than a new one, say so in your answer and let the user decide.
- **Comment only when the user asks for that specific comment.** Draft it, show it,
  and wait for approval. One approval covers one comment.

## Before you finish (checklist)

- [ ] Everything written passes the read-aloud test: a sentence a teammate would
      say, not one lifted from a design document. Nothing narrates one
      hypothetical instance, chains possessives, picks a verb for flavor where a
      plain one exists, or re-derives the mechanism in a trailing clause.
- [ ] American English in all prose. Spelling is preserved only in a quoted
      identifier, API name, string literal, or quoted text, in a new name joining a
      family the repository already spells the British way, and where a standard,
      schema, or protocol fixes it.
- [ ] No prescribed implementation details; the issue says what and why, not how.
- [ ] No conversational phrases or filler.
- [ ] No rhetorical construction, personification, or judgment adverbs.
- [ ] No jargon and no em dashes.
- [ ] Each section is a few sentences or tight bullets at most.
- [ ] Every enumeration of two or more items is a bulleted list, not inline prose.
- [ ] Title is short and specific.
- [ ] Any repository issue template was followed.
- [ ] Nothing posted as a comment or reply, and the issue was filed only after
      approval.
