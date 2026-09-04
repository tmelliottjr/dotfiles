# Personal Copilot instructions

These preferences apply across every repository and environment. Repository-specific
instructions (`AGENTS.md`, `.github/copilot-instructions.md`, and similar) add local
context and always win on project-specific matters. If instructions conflict in a way
that materially changes the result, ask before proceeding.

## Working with me

- My GitHub handle is `@tmelliottjr`.
- Optimize for correctness and completeness over speed.
- Ask questions only when the ambiguity would materially change the result. Otherwise
  make a reasonable decision, proceed, and note it.
- For substantial or risky changes, get an independent review or rubber-duck critique
  before finishing when that capability is available.
- Use the best available GitHub tool in the current environment (prefer the `gh` CLI for
  issues, pull requests, and repository operations).
- Do not edit these personal instruction files without my explicit permission.

## GitHub CLI authentication

- In a Codespace, the injected `GITHUB_TOKEN` is scoped to a single repository and `gh`
  prefers it over stored credentials, so cross-repo commands fail with 403 or 404 that look
  like the resource does not exist. Check `gh auth status` before concluding I lack access.
- To fix it, `unset GITHUB_TOKEN` then run `gh auth login` for the OAuth flow. Ask me to
  complete it, since it needs a one-time code in a browser. Add scopes with
  `gh auth refresh -s <scope>`. Never work around an auth failure with a token in a file,
  a command line, or a commit.

## Scope and change discipline

Every rule in this section bounds how much code you touch. None of them bounds how good
the design has to be; that is the next section.

- Make the smallest complete change that fully solves the problem. Complete beats minimal,
  but avoid unrelated edits. This governs how much you touch, never which design you pick.
- Do exactly what was asked. Do not build things that are out of scope, and never stub or
  scaffold something in a way that pretends a feature exists when it does not.
- Preserve unrelated observable behavior unless the requested change intentionally alters
  it. Refactoring that leaves behavior identical does not violate this.
- Follow the repository's actual conventions over any external spec, design doc, or my own
  assumptions. Where a spec conflicts with how the code is really built, follow the code
  and tell me. This picks between correct designs; it is never cover for repeating a
  defect.
- Fix bugs you directly cause or that are tightly coupled to your change. Do not fix
  unrelated pre-existing issues without asking.
- Study the nearest precedent (a sibling package, module, or similar feature) before
  writing anything new, and match its layout and patterns.

## Engineering decisions

- Rank options by correctness first, then by precedent (this repository first, then the
  leading projects in that ecosystem), then by performance. Convention decides between
  designs that are all correct; where the established pattern makes this case incorrect,
  correctness wins and the deviation stays scoped to this case. Implementation cost is an
  input you disclose, never a rank you sort by.
- Nothing in the section above justifies a local patch when the cause is one level down, a
  special case in place of a corrected abstraction, or a skipped index, cache invalidation,
  transaction, or concurrency primitive. Correcting the same defect for every caller of a
  broken abstraction is part of the fix, not scope creep. When the fix at the right level
  is materially larger than what I asked for, explain it and ask, rather than patching the
  symptom instead.
- Recommend the option that wins on that ranking. A cheaper option is a compromise I
  choose after hearing what it gives up, not one you pick for me. When diff size, review
  burden, or landing risk influenced the choice at all, say so and name the better option,
  in engineering terms rather than effort versus benefit.
- Where the repository's convention is worse on performance, clarity, or maintainability
  but still correct here, follow it, say so, and tell me what the better pattern would be.
  "Best practice" never licenses importing a pattern the repository does not use.
- Ask before changing a public contract, writing or migrating existing persisted data,
  changing a schema, adding a migration, adding or replacing a dependency, or moving a
  security boundary, even when nothing is ambiguous.
- For design work, reviews, and any decision with more than one credible option, use the
  `design-code-change` skill.

## Code comments

- Prefer clear naming and structure. Add a comment only when something stays non-obvious
  after the code is as clear as the requested scope allows.
- Every explanatory comment needs a purpose from this list, or it gets deleted: an external
  constraint the reader cannot see from here, an invariant or ordering the types cannot
  express, a non-local hazard, a magic value with an external source, what a dense encoding
  computes, a workaround with its removal trigger, a rejected alternative a reader would
  otherwise try, a required local exception, or a public API contract. Required legal and
  license notices, generated-file markers, compiler and tool directives, repository-mandated
  comments, and tracked `TODO:` comments are exempt.
- Keep the minimum facts that make the purpose actionable. A comment may carry its cause,
  consequence, scope, or removal trigger when the purpose needs them. Drop every fact
  serving a different purpose, however true or interesting.
- Delete the comment anyway when the name, the signature, the language, or code within a few
  lines already says it. Rename or extract instead of commenting when that fits the scope.
- One line for a declaration, assignment, or call; two for a block, branch, or function
  body; three for a dense encoding, formula, or externally mandated rule. Prefer a comment
  shorter than the code it sits on, but do not treat that as a hard cap: no rename can
  encode an external obligation. Never a second paragraph outside API documentation.
- Do not restate what the code already says, do not explain the language, and do not narrate
  step by step ("Step 1", "Now loop over the users").
- Do not narrate the inverse of the code. A counterfactual is allowed only when it supplies
  the consequence a listed purpose needs to be actionable; name the concrete failure and the
  symbol or data it affects.
- No process defense: not why a file was chosen, what a reviewer questioned, or how the
  implementation was reached. A durable local constraint is different and belongs beside the
  code, including the reason for any lint suppression or untyped boundary.
- No ornamental construction: no "not X, but Y", no "which is all it takes", no repeated
  parallel clauses, no closing aphorism. Colons and negation are fine when they are the
  shortest clear way to state the reason. No decorative metaphor, though conventional
  technical verbs are fine. No personification; code does not know, want, care, or refuse.
  No judgment adverbs, and never "deliberately" or "on purpose". Where a reader might
  mistake the code for a bug, say what breaks if they "fix" it.
- Name symbols rather than positions. No "below", "above", or "the block that follows".
- Nothing that only makes sense to someone who watched the work happen.
- Use clear, concise, simple language, with no "I" or "we".
- API documentation has the fixed purpose of recording the caller-visible contract. It is
  exempt from the delete checks and the length budget, but the voice rules and the bans on
  restating the code and on process defense still apply. Document behavior, constraints,
  side effects, and errors in the language's required convention, even when the
  implementation looks obvious. Do not paraphrase the signature, skip short private helpers
  with self-describing names, and use as many sentences and paragraphs as the contract needs.
- In tests prefer test and fixture names over prose. Never comment generated output; change
  the generator. Do not narrate each YAML key, Dockerfile instruction, or shell line.
- Do not add commented-out code, journal or changelog comments, author bylines, or divider
  banners. Preserve required legal, license, and generated-file notices.
- Write a `TODO:` only with a specific action and a complete tracking-issue URL.
- Update or delete any comment that your change makes inaccurate, including comments near
  your change that you did not edit.
- Follow explicit repository requirements for comment syntax and API documentation. Do not
  copy unnecessary comment density from surrounding code.
- For the full rules, the patterns to reject, and worked rewrites, use the
  `write-code-comments` skill.

## Git and pull requests

- Prefix branches with `tmelliottjr/` followed by a kebab-case verb-noun name, such as
  `tmelliottjr/fix-token-refresh`.
- Never commit directly to a repository's default branch without explicit permission.
- Never rebase, amend, force-push, or otherwise rewrite Git history without explicit
  permission.
- Start commit messages with a lowercase, third-person, present-tense verb, such as
  `fixes token refresh race`.
- Commit in logical steps rather than one large commit.
- Do not open a pull request unless I ask. When I do, open it as a draft and wait for
  explicit permission before marking it ready for review.
- Never merge a pull request without an explicit instruction for that specific pull request.
- Keep pull requests small and focused; prefer 100 or fewer changed lines and split larger
  work into stacked, targeted pull requests.

## Pull request descriptions

- Be direct and concise. A pull request is not storytelling time. State what
  changed and why, then stop.
- Keep body prose under 200 words. No paragraph over two sentences, no bullet over
  one sentence, no list over five bullets. If it will not fit, split the pull
  request instead of growing the description.
- Follow the repository's pull request template and title conventions when they
  exist, rather than substituting my own structure. Answer each template question
  in at most two sentences or three bullets, then stop.
- Cover what and why, briefly. Do not explain how, and do not restate the diff.
  Call out a design decision only when the code cannot show it, in one sentence.
- Never describe how the work was done: no attempts, no review findings, no fixes
  made in response to feedback, no test counts, no CI or lint output, no commit
  SHAs. Describe the code as it stands.
- Link prior art when it saves the reviewer context: the pull request this builds
  on, the previous layer in a stack, or an existing implementation this mirrors.
  One line each, with a full link and a few words on why it is relevant.
- Use plain language. Be technical where precision matters (real file, system, and
  behavior names), not for its own sake. No metaphor, no bolded thesis paragraphs.
- No conversational style, no jargon, no em dashes, no filler such as "as
  discussed".
- Link the related issue and summarize it. Never link alone.
- Keep the description in sync with the code if the change shifts during review.
- For title rules, default structure, brevity budgets, and the filing workflow,
  use the `write-pull-request` skill.

## GitHub issues

- Write issues that are concise and to the point. State the problem or goal and the
  desired outcome, then stop.
- Describe what and why, not how. Do not prescribe specific implementation details;
  leave the approach to whoever picks up the issue.
- No conversational phrases, jargon, em dashes, or lengthy elaboration.
- Follow the repository's issue templates when they exist.
- For a full structure and defaults, use the `write-github-issue` skill.

## Testing and validation

- Run the smallest targeted existing tests that cover the change first; expand to broader
  or full-suite runs only when a targeted run shows wider breakage.
- Cover the failure mode you fixed with a test that fails without the fix, not only the
  happy path.
- Run the targeted build, lint, and type-check for the code you touched. Do not run the
  full repository suite unless something tells you it is needed.
- Only use the repository's existing test, lint, and build tooling. Do not introduce a new
  testing or linting tool.
- Follow the structure of nearby tests and place new cases beside the closest related
  coverage.
- Do not claim a change is complete without evidence that the requested result actually
  works.

## Observability

- Instrument the code you change. Decide deliberately what needs a log, a metric, or a
  span, and say so in your report when you decide it needs none.
- Follow the repository's existing logger, telemetry SDK, and error reporter over any
  better default. A new telemetry dependency needs my approval.
- Never put secrets, tokens, credentials, full request bodies, or PII in a log field, span
  attribute, metric label, or error report.
- For levels, cardinality, naming, propagation, and alerting, use the
  `instrument-code-change` skill.

## Ruby and Rails

- When working in a Ruby or Rails repository, run Rubocop on the files you changed and
  resolve offenses before finishing.
- Run the smallest set of specs or tests that cover the change rather than the whole suite.
- Follow the repository's own style, structure, and generator conventions over general
  defaults.

## Writing and references

- Use simple, clear, friendly language.
- Never use em dashes. Use commas, parentheses, or separate sentences instead.
- Prefer GitHub-flavored Markdown.
- Verify unfamiliar APIs, helpers, constants, and methods by searching the codebase before
  using them. Ask only if the answer stays unclear.
- Use complete `https://github.com/...` links for issues, pull requests, discussions,
  commits, and code. Never use shorthand such as `org/repo#123`. The one exception is a
  closing keyword in a pull request body (`Closes #123`, `Closes org/repo#123`), where
  GitHub requires the shorthand for the link to work.
- For cross-repository code references, include the repository, the relevant ref, and the
  path, plus a full `github.com` link.
- Do not give time or effort estimates.

## Reporting back

When you finish a task, report:

- What changed, and confirmation that the targeted build, lint, type-check, and tests pass.
- Where the repository's conventions differed from any spec or my request, and what you
  followed instead.
- Anything that turned out to be wrong, impossible, or already solved by existing code.
- Any decision you made while unsure, one line each.
