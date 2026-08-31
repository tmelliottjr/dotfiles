---
name: github-pr-writing
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

A pull request description exists to get a reviewer productive fast. Say what
changed and why it changed. The diff already shows how.

## Style rules (always apply)

- **Direct and concise.** Every line earns its place. Short sentences, tight
  bullets. If a section runs past a few sentences, cut it.
- **No storytelling.** Do not narrate the journey ("first I tried X, then I
  noticed Y, so I went with Z"). Give the conclusion, not the exploration.
- **No conversational style.** Drop openers, filler, and asides such as "Hey
  team", "So basically", "I was thinking", "Just a small one", "As discussed",
  "Hope this helps". No emoji unless the repository's template uses them.
- **What and why, not how.** Describe the change and the reason for it. Do not
  walk the reviewer through the implementation line by line or restate the diff.
  Mention a design decision only when the diff cannot explain it (a tradeoff, a
  rejected alternative, a constraint, a deliberate limitation).
- **Plain language, technical where it matters.** Use the real names of the
  systems, files, endpoints, and behaviors involved. Skip buzzwords and internal
  shorthand a new reviewer would not recognize.
- **Stand alone.** Never make the body just a ticket link. Link the issue *and*
  summarize it.
- **No em dashes.** Use commas, parentheses, or separate sentences.
- **Present the facts.** No effort or time estimates, no self-congratulation
  ("cleaned this up nicely"), no apologies.

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

**Always check for a template first.** If the repository has one, keep its
headings and their order, fill in every required section, and honor its
instructions about optional sections. Remove the HTML comment instructions and
any placeholder text. Do not substitute the default structure below. Leave no
unchecked box for something that is actually done.

When there is no template, use this shape and drop any section with nothing
useful to say:

```markdown
## Summary
One to three sentences: what this change does, in plain language.

## Why
One to three sentences: the problem, bug, or goal behind it. Link the issue.

## Changes
- Grouped by concept or area, not file by file.
- One line each. Note anything a reviewer would otherwise miss.

## Testing
How this was verified. Name the commands or tests that were run.

## Notes (optional)
Follow-ups, known gaps, deliberate omissions, migration or rollout steps.
```

Section guidance:

- **Summary.** The reviewer should understand the change from this alone.
- **Why.** The part the diff can never show. Skip it only when the title makes
  it self-evident (a typo fix, a version bump).
- **Changes.** Group related edits into a handful of bullets. Skip this section
  entirely on a small, single-purpose PR where the summary already covers it.
- **Testing.** State what was actually run and its result. Do not claim coverage
  that does not exist. If it was not verified, say so plainly.
- **Screenshots or recordings.** Include them for any user-visible change. Use
  before and after when behavior changed.
- **Breaking changes.** Call them out explicitly near the top, with the
  migration step they require.

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
4. **Draft in Markdown** and show it to the user.
5. **Filing.** An explicit request to open, create, or file the PR is approval to
   create it as a draft. If the user only asked for the copy, show the draft and
   wait.
6. **File it with the GitHub CLI** as a draft:

   ```bash
   gh pr create --draft --title "<title>" --body-file <path>
   ```

   Use `--body-file` rather than `--body` so Markdown and newlines survive. Add
   `--base` for a stacked or non-default target branch. Add `--reviewer`,
   `--label`, or `--assignee` only when asked. Return the full
   `https://github.com/...` PR URL.
7. **Do not mark it ready for review** and do not merge it without an explicit
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
- [ ] The repository's PR template was used and its required sections filled in.
- [ ] Body says what changed and why, and does not restate the diff.
- [ ] No storytelling, no conversational filler, no em dashes.
- [ ] Issue linked, with a closing keyword when the PR targets the default
      branch.
- [ ] Testing states what was actually run.
- [ ] Screenshots included for user-visible changes.
- [ ] Opened as a draft, and not marked ready or merged without being asked.
