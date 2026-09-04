---
name: write-pull-request
description: >
  Use this skill whenever the user asks to write, draft, prepare, create, open,
  file, update, revise, rewrite, or improve a GitHub pull request or PR, or asks
  for a PR title, PR description, PR body, or PR summary (for example "open a PR
  for this", "write the PR description", "draft a pull request", "update the PR
  body", "clean up this PR summary"). It produces direct, concise PR titles and
  descriptions that state what changed and why, follow the repository's PR
  template when one exists, and file them with the GitHub CLI on request.
---

# GitHub PR Writing

A pull request description gets a reviewer productive in the next twenty
minutes. Say what changed and why. The diff already shows how.

Two failure modes matter, and the second is the common one:

- **Too little.** "Fix bug", "Update user service", "Address feedback".
- **Too much.** An essay that argues its own case, narrates how the work was
  done, and buries the change in prose the reviewer has to mine.

## Budget

Hard limits, not targets. Under is fine. Over is a defect.

| Part | Limit |
| --- | --- |
| Body prose you write, excluding template headings, checkboxes, and links | 200 words |
| Opening summary | 3 sentences |
| Any paragraph | 2 sentences |
| Any bullet | 1 sentence |
| Any bullet list | 5 bullets |
| Any answer to a template question | 2 sentences, or 3 bullets |

If the change will not fit, the pull request is too big. Split it into stacked
pull requests. Never grow the description to compensate for a large diff.

## Never include

- **How the change was made.** No account of what was tried first, what a review
  found, what got fixed in response, or what changed between pushes. Describe the
  code as it stands, as if it had always looked this way.
- **A per-file or per-commit walkthrough.** The diff already has one.
- **Test, lint, or CI output.** Test counts, coverage percentages, and mutation
  scores are noise. One line naming what was run is enough.
- **A review record.** No finding counts, agent logs, self-assessment, or claims
  about how thorough the work was.
- **Commit SHAs or branch names.**
- **Instructions about how to review.** Do not ask the reviewer to read carefully
  or to pay attention to a section. Boilerplate the template itself supplies
  stays as written.
- **Anything already stated in another section.**

## Voice

- **One idea per sentence.** Short sentences, plain words. Say "use", not
  "utilize". Cut adverbs ending in -ly.
- **No metaphor, imagery, or rhetorical build.** Write "the arrow keys now reach
  the paging placeholders", not "every place a reader can end up is a place the
  keyboard reaches".
- **No personification.** Code does not know, want, care, decide, refuse, or feel
  anything. Write "the reducer ignores drag state", not "the reducer does not
  care about drag state".
- **No bolded thesis followed by an argument.** That is an essay. A pull request
  states the decision in a sentence and moves on.
- **No defending against objections nobody raised.** Do not argue for a choice
  the reviewer has not questioned. State the decision and the constraint that
  forced it, and let review ask for the rest.
- **Say it once.** No "in other words", "put differently", "essentially". A
  sentence that needs restating was wrong the first time.
- **Present tense, active voice, describing the code as it is now.** Not "was
  investigated", "was deliberately not adopted", "has been made concrete".
- **No conversational filler.** No "Hey team", "So basically", "I was thinking",
  "Just a small one", "As discussed", "Hope this helps". No emoji unless the
  repository's template uses them.
- **Plain language, technical where it matters.** Use the real names of the
  systems, files, endpoints, and behaviors involved. Skip buzzwords and internal
  shorthand a new reviewer would not recognize.
- **No em dashes.** Use commas, parentheses, or separate sentences.
- **No judgment adverbs.** Drop "deliberately", "carefully", "properly",
  "nicely", "simply". No effort or time estimates, no self-congratulation, no
  apologies.
- **Stand alone.** Never make the body just a ticket link. Link the issue *and*
  summarize it in a sentence.

## Lists

Long paragraphs are hard to scan. Prose carries one idea. Anything countable goes
in a list.

- **Break every enumeration out of the sentence.** Two or more items,
  conditions, changes, or affected areas become bullets under a one-line lead-in
  ending in a colon. Do not run them inline behind "and" or behind a colon.
- **Keep bullets as fragments.** No repeated lead-in words, no trailing periods,
  one line each.
- **Leave the rest of the prose outside the list,** in its own short paragraph
  after it.
- **Do not bullet a single item,** and do not split one idea across bullets to
  look structured.
- **Never nest.** One level only. A sub-bullet means the parent is two items.
- The budget still applies: five bullets at most, one sentence each.

> ❌ Adds the remaining keyboard focus positions to the board: the three paging
> placeholders and each swimlane name.
>
> ✅
>
> > Adds the remaining keyboard focus positions to the board:
> >
> > - paging placeholders
> > - swimlane names

## Title

- One line, imperative mood by default, describing what the change does. Test it
  against "If applied, this pull request will ___".
- Aim for 50 characters and stay under 72 unless the repository sets another
  limit. Long titles get visually clipped in some GitHub views.
- No trailing period. No `[WIP]` prefix (use a draft PR instead).
- Never a bare ticket number or a vague verb on its own.
  - Good: `Fix token refresh race on concurrent requests`
  - Good: `Remove the unused legacy billing webhook`
  - Avoid: `JIRA-1234`, `Fix bug`, `Updates`, `WIP`, `Address feedback`
- **The repository's convention wins over every default above**, including
  imperative mood. Check `CONTRIBUTING.md` and the repo's recent *merged PR
  titles* first. Fall back to commit subjects only when the repo documents that
  PR titles become or must match commit subjects.
- If the repo uses Conventional Commits (a `commitlint` config, a PR title lint
  workflow, or documented policy), use its prefix:
  `fix(auth): reject expired refresh tokens`.
- Under squash merging the PR title may become the squash commit subject,
  depending on repository settings and edits made at merge time. Where that
  applies, treat the title with the same care as a commit message.

## Body

### Filling a repository template

Most repositories have one, and this is where descriptions go wrong most often.
A template's questions are prompts for a sentence or two, not essay titles.

- Keep the template's headings, their order, and every required section. Do not
  add sections it does not ask for, and do not substitute the structure below.
- **Answer each question in at most 2 sentences or 3 bullets, then stop.** A
  question with a one-word answer gets one word.
- **Never stuff a bullet to stay under the cap.** When a question covers more
  decisions than fit, drop the least important ones rather than packing two
  unrelated points into one sentence. A reviewer can ask about what is missing.
- Check the boxes that apply. Leave no box unchecked for something that is done,
  and do not explain a box you checked.
- Remove the HTML comment instructions and placeholder text, but keep any comment
  the template says to preserve, such as a version marker or a label trigger.
- "What approach did you choose and why" wants the decision and the constraint
  that forced it, not the reasoning that led there. One sentence each.
- "How did you validate this change" wants the kind of validation, not the
  results. "Unit tests and a Storybook check", not a test count.
- List a rejected alternative only when a reviewer would otherwise propose it.
  One line, and link where the detail lives if it is written down.
- List a known gap or deferred fix only when it affects review or rollout. One
  line each, capped at three.

### Default structure (no template)

Use this shape and drop any section with nothing useful to say:

```markdown
## Summary
One to three sentences: what this change does, in plain language.

## Why
One or two sentences: the problem, bug, or goal behind it. Link the issue.

## Changes
- Grouped by concept or area, not file by file.
- One line each, five at most.

## Testing
One or two lines naming what was run.

## Notes (optional)
Follow-ups, known gaps, deliberate omissions, migration or rollout steps.
```

Section guidance:

- **Summary.** The reviewer should understand the change from this alone.
- **Why.** The part the diff can never show. Skip it only when the title makes it
  self-evident (a typo fix, a version bump).
- **Changes.** Skip this section entirely when the summary already covers it.
- **Testing.** Name what was actually run. Do not claim coverage that does not
  exist. If it was not verified, say so in one line.
- **Screenshots or recordings.** Include them for any user-visible change. Use
  before and after when behavior changed.
- **Breaking changes.** Call them out explicitly near the top, with the migration
  step they require.

## Prior art

Link precedent when it saves the reviewer from reconstructing context. Good
candidates:

- The pull request this one builds on, or the previous layer in a stack.
- An existing implementation this change mirrors, so the reviewer can compare
  against something already approved.
- The pull request or ADR that established the pattern being applied here.
- The issue, spec, or design doc that defines "done".

One line each, with a full `https://github.com/...` link and a few words on why
it is relevant. Never link alone, and never link something the reviewer does not
need.

> Builds on https://github.com/github/github-ui/pull/31757, which added the
> roving focus framework. Follows the same reducer shape as `packages/board-core`.

## Linking issues

- Closing keywords make the issue close on merge. GitHub recognizes exactly
  nine: `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`,
  `resolves`, `resolved`.
- Syntax is `Closes #123`, or `Closes owner/repo#123` across repositories. This
  shorthand is required for the keyword to work, so use it here even though full
  `https://github.com/...` links are the rule everywhere else.
- Put it on its own line for readability. GitHub does not require that.
- Multiple issues need the keyword repeated: `Closes #12, closes #34`.
- **Closing keywords only work when the PR targets the repository's default
  branch.** On any other target branch GitHub ignores the keyword entirely and
  creates no link. There, reference the issue with a full
  `https://github.com/...` link instead, and add the closing keyword if the PR
  is later retargeted to the default branch. In a stack, this usually means only
  the bottom PR carries the closing keyword.
- When there is no issue, do not invent one.

## Rewrites

The same content, over budget and in budget. The pattern to learn is that the
right version keeps every fact a reviewer acts on and drops the argument around
it.

**Opening**

> ❌ Fifth open layer of the shared board packages. The roving focus framework
> landed in `<link>`; this one finishes it, so every place a reader can end up on
> the board is a place the keyboard reaches, and it reports what they are
> touching.

> ✅
>
> > Adds the remaining keyboard focus positions to the board:
> >
> > - paging placeholders
> > - swimlane names
> >
> > Builds on `<link>`, which added the roving focus framework.

**Design decision**

> ❌ **Four new focus positions, not four new tab stops.** `views#43` asks that
> each of the three load-more controls be a focus stop. There is no control: the
> board pages by scrolling a sentinel into view, and each direction draws a still
> `<p>` ghost saying more exists. Giving non-interactive text a `tabindex` would
> put an element nobody can operate into the page's tab order and give the board
> a second way in. So `BoardFocusPosition` gained a `kind`, and the three ghosts
> and each swimlane's name became coordinates the focus model can name.

> ✅ The paging placeholders are focus positions, not tab stops. They are static
> text with no control to operate, so a `tabindex` would add a second way into
> the board. The board stays one tab stop.

**Rejected alternative**

> ❌ `role="grid"` was investigated as the fix for browse mode and deliberately
> not adopted. `grid` is a two-dimensional role and this board is
> three-dimensional (column by swimlane by card index): making a cell a
> `gridcell` leaves its cards outside the pattern, and making a card one forces a
> cell to be a `row`, which collides with swimlanes. It would also cost the
> `aria-posinset` and `aria-setsize` a windowed cell's cards carry...

> ✅ Not using `role="grid"`: the role is two-dimensional and this board is three
> (column, swimlane, card index). Reasoning is in `packages/board/README.mdx`.

**Validation**

> ❌ 42 new tests, 358 passing across the two packages, alongside lint, stylelint
> and type-check on both. Nineteen mutations were applied to the new code and
> eighteen failed a test; the one that did not is the guard that declines a key
> when the scrolling container has nowhere left to go...

> ✅ Unit tests, lint, and type-check on both packages. Four new stories,
> verified in Storybook locally.

**Known gaps**

> ❌ an accessibility review and an independent code review both ran, and both
> independently found the same critical bug, which was real and is fixed here: a
> focused paging ghost that unmounts... Alongside it: carried keys are now
> concrete, so a position read back never holds a placeholder...

> ✅ Two known gaps, documented in `packages/board-core/README.mdx`: focus moving
> to a row header menu still reports the previous card, and a row header that
> never calls `useBoardRowHeader` leaves an unreachable position. Neither loses
> focus or fails WCAG.

## Workflow

1. **Read the actual change.** Run `git --no-pager log <base>..HEAD` and
   `git --no-pager diff <base>...HEAD --stat` (plus the full diff when it is
   small) so the description reflects the code, not the intent.
2. **Check the repository.** Run `gh repo view` to confirm the target repo and
   default branch. Look for a template at `.github/pull_request_template.md`,
   `.github/PULL_REQUEST_TEMPLATE.md`, `docs/pull_request_template.md`,
   `pull_request_template.md`, or multiple templates under
   `.github/PULL_REQUEST_TEMPLATE/`, `PULL_REQUEST_TEMPLATE/`, or
   `docs/PULL_REQUEST_TEMPLATE/`. Also check `CONTRIBUTING.md` for title and
   description rules.
3. **Check the title convention** in recent merged PR titles before writing the
   title.
4. **Find the prior art.** Check whether this builds on another pull request, has
   a parent in a stack, or mirrors an existing implementation worth pointing at.
5. **Draft in Markdown**, writing only from the final state of the code. Never
   from your own session history: if a sentence only makes sense to someone who
   watched the work happen, it does not belong in the description.
6. **Make a cut pass before showing it.** This step is not optional, and it is
   what keeps the description useful.
   - Delete every sentence that does not change what the reviewer does.
   - Delete every sentence that describes the process rather than the code.
   - Collapse each remaining paragraph over 2 sentences.
   - Count the words. Over 200, cut again rather than rationalizing.
7. **Show the draft to the user.**
8. **Filing.** An explicit request to open, create, or file the PR is approval to
   create it as a draft. If the user only asked for the copy, show the draft and
   wait.
9. **File it with the GitHub CLI** as a draft:

   ```bash
   gh pr create --draft --title "<title>" --body-file <path>
   ```

   Use `--body-file` rather than `--body` so Markdown and newlines survive. Add
   `--base` for a stacked or non-default target branch. Add `--reviewer`,
   `--label`, or `--assignee` only when asked. Return the full
   `https://github.com/...` PR URL.
10. **Do not mark it ready for review** and do not merge it without an explicit
    instruction for that specific PR.

## Updating an existing PR

- When the change grows or shifts during review, update the description so it
  still matches the code. A stale description is worse than a short one.
- Read the current body first with
  `gh pr view <number> --json title,body`, and preserve template sections and
  anything the user wrote by hand.
- Update with `gh pr edit <number> --title "<title>" --body-file <path>`.

## Size

Keep PRs small and focused, ideally 100 or fewer changed lines. If a change is
too large to describe in a short summary, say so and propose splitting it into
stacked PRs rather than writing a longer description to compensate.

## Before you finish (checklist)

- [ ] Title is specific, under 72 characters, and has no trailing period.
- [ ] Title matches the repository's own PR title convention.
- [ ] The repository's PR template was used, and each of its questions answered
      in 2 sentences or 3 bullets at most.
- [ ] Body prose is under 200 words. No paragraph runs past 2 sentences.
- [ ] Every enumeration of two or more items is a bulleted list, not inline prose.
- [ ] Body says what changed and why, and does not restate the diff.
- [ ] Nothing describes how the work was done: no attempts, no review findings,
      no fixes made in response to feedback, no test counts or CI output.
- [ ] No metaphor, no personification, no bolded thesis paragraphs, no
      conversational filler, no em dashes.
- [ ] Nothing defends a choice against an objection nobody raised.
- [ ] Prior art linked where it saves the reviewer context, with one line of why.
- [ ] Issue linked, with a closing keyword when the PR targets the default
      branch.
- [ ] Testing names what was run, without results or counts.
- [ ] Screenshots included for user-visible changes.
- [ ] Opened as a draft, and not marked ready or merged without being asked.
