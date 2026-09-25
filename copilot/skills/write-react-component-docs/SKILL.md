---
name: write-react-component-docs
description: >
  Use this skill whenever writing, reviewing, trimming, or rewriting
  documentation for a React component, prop, or hook: TSDoc or JSDoc on a props
  type, a component's doc block, prop tables, Storybook argType descriptions, or
  component MDX (for example "document this component", "add JSDoc to these
  props", "write prop docs", "document the props on this type", "clean up these
  component docs", "why is this prop missing from the docs table"). It also
  applies with no prompting when a change adds, renames, or alters a public prop,
  since that is when the prop table gets written. It produces one-line prop docs
  in the grammar React Aria, Primer, MUI, Mantine and Polaris actually use,
  records defaults in the tag the repository's docgen actually reads, and keeps
  narration, scenarios, and personification out of the API surface.
---

# React Component Documentation

A prop doc is a contract entry, not an explanation. Say what the prop controls,
what constrains it, and what happens by default. Then stop.

The failure this skill exists to prevent is the prop doc written as prose:

```ts
/**
 * rowHeight is a CSS length, applied identically whether the board has one row
 * or twelve. It defaults to 100% of the scroll viewport, which is what a board
 * with no swimlane wants. A swimlaned board sets a fixed size and scrolls
 * downwards through bands of equal depth.
 */
rowHeight?: string
```

Four sentences carrying one fact. It restates the name and the type
(`rowHeight is a CSS length`), pads with ornamental contrast (`one row or
twelve`), personifies the component (`which is what a board with no swimlane
wants`), buries the default in prose where no docs table can find it, and closes
with a scenario. A caller needs this:

```ts
/**
 * Height of every row, as a CSS length. A fixed length scrolls the board
 * vertically when rows overflow the viewport.
 * @default '100%'
 */
rowHeight?: string
```

## Read the repository first

Every default below loses to what the repository already does.

| Find | How |
| --- | --- |
| The docgen pipeline | `react-docgen`, `react-docgen-typescript`, `@microsoft/api-extractor`, `typedoc`, or a house script in `package.json` and `.storybook/main.ts`. This decides which tags survive and which default tag to write. |
| The prop grammar | Read twenty existing prop docs in the nearest sibling component. If they are sentence fragments with no trailing period, write fragments with no trailing period. |
| Where descriptions are authored | Some systems author prose in a separate file (Primer's `*.docs.json`, Chakra's extracted Ark UI types) and the TSDoc is secondary. Edit the file the site actually reads, and keep both in sync when both exist. |
| Whether docs are generated | MUI regenerates `propTypes` and API pages from the `.d.ts` JSDoc, so hand-editing the generated file is discarded. Find the generator before writing. |
| Release tags | An API Extractor project requires `@public`, `@beta`, `@alpha`, or `@internal` on every export. |

## Where the docs go

The extractor decides placement:

- **One `/**` block immediately above the prop, inside the props type.** Only the
  closest preceding block counts, and `//` comments are ignored entirely.
- **Props typed inline in the component signature get no docs.** Declare a props
  interface or type alias.
- **`children` needs an explicit description or it disappears.**
  react-docgen-typescript drops an undocumented `children`
  (`skipChildrenPropWithoutDoc` defaults to `true`). This is why Primer writes
  "The content of the button." and MUI "The content of the component."
- **The first sentence is the summary.** TSDoc defines paragraph one as the
  summary and `@remarks` as the detail; Storybook shows the leading text in the
  control table. Lead with the contract, never with context.
- **`@default` and `@type` are stripped out of the rendered description.**
  `@deprecated`, `@see` and `@example` are not: their text is appended to the
  description in Storybook. Write them as sentences that survive that.

### Which default tag

| Pipeline | Tag |
| --- | --- |
| Storybook autodocs, react-docgen-typescript | `@default` |
| API Extractor, TypeDoc, a TSDoc linter | `@defaultValue` |
| Radix Primitives and anything following it | `@defaultValue` |
| Nothing configured | Match the file: `grep -c '@default\b'` against `@defaultValue`. `@default` is what Primer, MUI, Mantine, Polaris, Ariakit and Fluent UI write, because it is what the docgen chain reads. |

`@defaultValue` is the TSDoc standard tag and `@default` is the JSDoc spelling.
Only one of them populates the default column in a given repository. Never record
a default only in prose, and never state a default the code does not set.

## Prop grammar

Match the category. React Aria is the tightest of these and the best model to
copy; the rest confirm the same shapes.

| Prop kind | Write | Precedent |
| --- | --- | --- |
| Boolean | `Whether <effect of true>.` or ``If `true`, <effect>.`` | React Aria: `Whether the input is disabled.` / `Whether the input can be selected but not changed by the user.` Primer: `Whether the switch is turned on`. MUI: ``If `true`, the component is disabled.`` |
| Controlled value | `The current <thing> (controlled).` | React Aria: `The current value (controlled).` Mantine: `Controlled component value` |
| Uncontrolled default | `The default <thing> (uncontrolled).` or `The default <thing>. Use when the component is not controlled.` | React Aria: `The default value (uncontrolled).` MUI: `The default checked state. Use when the component is not controlled.` |
| Event handler | `Handler that is called when <event>.` or `Event handler called when <event>.` | React Aria: `Handler that is called when the value changes.` / `Handler that is called when a press interaction starts.` Radix and Base UI: `Event handler called when ...` MUI: `Callback fired when the state is changed.` Polaris: `Callback when clicked` |
| Enum or union | `The <axis> of the component.` plus `@default`. One `- 'value': meaning` bullet per member, and only where the member name does not say it. | MUI: `The variant to use.` Fluent UI documents each member as a bullet. |
| `children` | `The content of the <component>.` | MUI: `The content of the component.` Primer: `The content of the button.` |
| Render prop | `Renders <what>. Called with <what it receives> and must return <what>.` | Carbon: `A component used to render an icon.` |
| Polymorphic `as` or `asChild` | `The element or component rendered as the root.` plus `@default` | Radix: `Change the default rendered element for the one passed as a child, merging their props and behavior.` Carbon: `Specify how the button itself should be rendered.` Primer's `as` carries a `defaultValue` and no description. |
| `className`, `style`, rest props | Document once at the boundary, not per prop. Say which element receives them. | Fluent UI: ``The root slot receives the `className` and `style` specified directly on the `<Switch>` tag.`` MUI marks `className` `@ignore`. |
| Accessible name or description | `<What> announced to screen readers <when>.` | Primer: `The content to announce to screen readers when loading`. Polaris: `Visually hidden text for screen readers` |
| Ref | Only when the target is not obvious from the type. | Mantine: `Assigns ref of the root element` |
| Data or collection | `The <items> in the <component>.` Say the ordering when it is meaningful. | React Aria: `Item objects in the collection.` / `The contents of the collection.` |
| Superseded prop | ``**Not recommended, use `x` instead.** <why>`` | React Aria's `onClick` opens with a bold `Not recommended` line, then: ``` `onClick` is an alias for `onPress` provided for compatibility with other libraries. ``` |

Three rules cut across the table:

- **A handler is a noun phrase, not an action.** `Handler that is called when the
  value changes.`, never `Fires the change event.` and never `Call this when you
  want to know about changes.` No library in the survey writes a handler doc in
  the imperative or the second person.
- **State the effect, not the mechanism.** `Whether the switch is turned on`, not
  `Sets the internal checked state which drives the aria-checked attribute`.
- **Name the real symbol** when a prop constrains another prop, and put it in
  backticks: `onChange`, `rowLabel`, `defaultChecked`.
- **State precedence where props overlap.** Ariakit does this on every
  controlled pair: ``The default checked state of the checkbox. This prop is
  ignored if the `checked` or the `store` props are provided.``

### Callback arguments

Storybook prop tables do not render `@param`, so a constraint on a callback
argument belongs in the description, where every reader sees it. Reach for
`@param` only where the pipeline renders it (TypeDoc, API Extractor) or the
repository already uses it. TSDoc spells it `@param name - description`; MUI
writes the JSDoc form `@param {Type} name Description`. Follow the file.

## Budget

| Doc on | Limit |
| --- | --- |
| A prop | 1 sentence |
| A prop with a caller-visible constraint | 2 sentences |
| A prop that hands the caller an accessibility obligation | 3 sentences |
| One member of an enum | 1 line |
| A component | 2 sentences, plus an `@example` where usage is not obvious |
| A hook | 1 line per returned value, plus 1 sentence for a required provider or stability rule |

The second sentence has to earn its place. It is for a requirement, a precedence
rule between props, a conflict with another prop, a validation rule, an
accessibility obligation the caller inherits, or a concrete consequence of
getting it wrong. Not for a scenario, a rationale, or a restatement.

A third sentence is available for one case, and only one: an accessibility
obligation the caller has to satisfy. Fluent UI's `disabledFocusable` spends
three sentences on when the pattern is appropriate, and MUI's `loadingIndicator`
spends its second on what the node must contain (`role="progressbar"` with an
accessible name). A behavioral caveat is not an accessibility obligation and does
not buy a third sentence. Every major system's median prop doc is one clause.

This tightens the API documentation budget in `write-code-comments`, which
exempts API docs from any length limit. A prop contract fits in one or two
sentences. Component and hook docs may run longer.

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

## Voice in a prop doc

- Present tense, impersonal, indicative. Imperative is fine for an instruction to
  the caller (`Use when the component is not controlled.`).
- No "I", no "we", no "you". No emoji.
- Follow the file's existing convention on trailing periods. React Aria, MUI and
  Fluent UI end prop docs with a period; Mantine, Polaris and Primer mostly do
  not. Consistency within the file beats either choice.
- Backtick every symbol: prop names, values, elements, ARIA attributes.
- Write the value, not a description of the value: `@default 'medium'`, not
  `@default medium size`.

## Patterns to reject

**1. Restating the name or the type.** The type already says `string`. The name
already says `rowHeight`.

> ❌ `/** rowHeight is a CSS length. */`
>
> ✅ `/** Height of every row, as a CSS length. */`

**2. Scenario narration.** A story about a configuration the caller might be in.

> ❌ `/** A swimlaned board sets a fixed size and scrolls downwards through bands of equal depth. */`
>
> ✅ `/** A fixed length scrolls the board vertically when rows overflow the viewport. */`

**3. Personification.** Components do not want, know, care, expect, or decide.
Describe behavior instead.

> ❌ `/** Defaults to 100%, which is what a board with no swimlane wants. */`
>
> ✅ `@default '100%'`

> ❌ `/** A cell you stated no count for is handed no count. */`
>
> ✅ ``/** `count` is omitted for cells that have none. */``

**4. Second-person narrative.** Address the caller with the imperative, not with
"you", and never build a sentence around what the caller did.

> ❌ `/** Honor rowLabel when you get one. */`
>
> ✅ ``/** Include `rowLabel` when it is passed. */``

MUI's `Use when the component is not controlled.` is the shape to copy: an
instruction, no pronoun.

**5. Sensory or dramatic framing.** No hearing, seeing, journeys, or arrivals.

> ❌ `/** What a reader hears on the way into a cell. */`
>
> ✅ `/** Accessible name for a cell, announced when focus enters it. */`

**6. A default in prose.** Prose defaults do not reach the docs table and go
stale silently. When you move a default into the tag, delete the sentence that
stated it.

> ❌ `/** ... It defaults to 100% of the scroll viewport. */`
>
> ✅ `@default '100%'`

**7. Ornamental construction.** Contrast and cadence that add emphasis without
information. Named forms: `whether it has one row or twelve`, `not X, but Y`,
`which is all it takes`, repeated parallel clauses, a closing aphorism.

> ❌ `/** Applied identically whether the board has one row or twelve. */`
>
> ✅ Delete it. `every row` already said it.

**8. Implementation narration.** Memoization, internal state, render counts, and
which hook holds the value are not the caller's contract.

> ❌ `/** Stored in a ref and flushed in a layout effect to avoid a double render. */`
>
> ✅ Delete it, or move it to an implementation comment under `write-code-comments`.

**9. Preamble and hedging.** `This prop is used when you want to`, `Optionally
allows`, `Basically`, `Note that`. Lead with the fact.

> ❌ `/** This prop can optionally be used if you want to customize the label. */`
>
> ✅ `/** Label for the control. */`

**10. Repeating the component's description on every prop.** The component doc
block says what the component is. A prop doc says what the prop does.

**11. Process and session residue.** Why the prop was added, which issue prompted
it, what it used to be called, what a reviewer asked for. A rename belongs in
`@deprecated`; history belongs in the changelog.

**12. Documenting a prop the type already fully specifies, at length.** A
required, self-naming prop such as `id` or `name` on a native passthrough needs a
short line or `@ignore`, not a paragraph.

### The counterfactual that stays

A consequence sentence is allowed when it names the concrete failure and the
symbol it affects. That is contract information a caller cannot get from types.

> ✅ ``/** Include `rowLabel` when it is passed; without it every cell in a column has the same name. */``

Compare with the rejected version of the same fact, `dropping it names every cell
in a column identically`, which frames the outcome as something the caller did
wrong. Name the prop and the result instead.

## The component doc block

One sentence naming what it is, and where it is not obvious, one more naming when
to use it. Then an `@example` with the minimal working usage, and links.

```tsx
/**
 * An accessible, native checkbox component.
 */
```

Primer, verbatim. Add an example when a component cannot be used from its
signature alone (compound components, required context providers, render props):

```tsx
/**
 * A grouped, scrollable board of cards.
 *
 * @example
 * ```tsx
 * <Board columns={columns} onItemsMove={handleMove}>
 *   {(item) => <Card key={item.id} item={item} />}
 * </Board>
 * ```
 */
```

For a compound component, document the root and each part separately. Say which
part owns state and which parts must be nested inside the root.

Do not open with "This component", do not describe the visual design, and do not
list the props again. The prop table is generated.

## Deprecation

Always a tag, always with the replacement.

```ts
/** @deprecated Use `leadingVisual` or `trailingVisual` instead. */
icon?: React.ElementType
```

Primer and Polaris both mandate this shape in writing: Polaris's deprecation
guidelines specify `@deprecated Use [REPLACEMENT_ADVICE] instead`. Where the
repository also tracks status in a docs manifest (Primer's `"deprecated": true`
in `*.docs.json`) or emits a runtime warning (Polaris, for deprecated prop
values), do both. A deprecation with no named replacement is incomplete.

## Hooks

Open with what the hook provides, in React Aria's shape: `Provides the behavior
and accessibility implementation for a button component.` Then document the call
contract, not the internals:

- What it returns, by name, and what the caller must do with each part. When the
  hook returns props to spread, say which element they belong on.
- Argument constraints and required stability (a memoized callback, a stable ref
  object, an id that must not change between renders).
- Rules of hooks constraints beyond the standard ones: conditional use, required
  provider, required parent component.

State the required provider or parent explicitly. It is the single most common
runtime failure a hook doc can prevent.

`@param` belongs on a hook even where it does not belong on a prop: React Aria
writes `@param props - Props to be applied to the button.` and `@param ref - A
ref to a DOM element for the button.` on `useButton`, in the TSDoc
`name - description` form.

## Usage docs, stories, and MDX

Prop tables are generated, so never hand-maintain one. When the repository has
narrative docs alongside:

- **A story is documentation.** Name it for the case it demonstrates
  (`WithValidationError`, not `Example2`), and prefer adding a story over adding
  a paragraph.
- **MDX covers what a prop table cannot:** when to choose this component over a
  neighbor, composition patterns, and the accessibility obligations the caller
  takes on. Not a restatement of the props.
- **Storybook `argTypes` descriptions override the extracted comment.** Fixing a
  description there hides the drift from IDE users. Fix the source comment.
- **Every code sample must compile** against the current props. A sample using a
  removed prop is worse than no sample.

## Rewrites

**A callback prop written in second person.**

> ❌
> ```ts
> /**
>  * cell is what a reader hears on the way into a cell, and on a swimlaned board
>  * it is the only place the cell's count is announced. Honor rowLabel when you
>  * get one: dropping it names every cell in a column identically. A cell you
>  * stated no count for is handed no count, and must be named without one.
>  */
> cell: (options: CellLabelOptions) => string
> ```
>
> ✅
> ```ts
> /**
>  * Accessible name for a cell, announced when focus enters it. Include
>  * `rowLabel` when it is passed; without it every cell in a column has the same
>  * name. `count` is omitted for cells that have no count.
>  */
> cell: (options: CellLabelOptions) => string
> ```

Every fact a caller can act on survives: the name is announced on focus entry,
`rowLabel` must be included when present, the failure if it is not, and that
`count` can be absent. What goes is the framing.

**A boolean explained through its implementation.**

> ❌ `/** Sets isDragging on the internal reducer, which the cell subscribes to so it can paint the drop target. */`
>
> ✅ `/** Whether cards can be dragged between cells. */`

**An enum documented as prose.**

> ❌
> ```ts
> /**
>  * Which position to render the loading indicator. If you pass auto it goes at
>  * the end, unless there is a leadingVisual, in which case it goes at the start.
>  */
> ```
>
> ✅
> ```ts
> /**
>  * Position of the loading indicator.
>  *
>  * - `'auto'`: trailing, or leading when `leadingVisual` is set
>  * - `'leading'`: before the input
>  * - `'trailing'`: after the input
>  *
>  * @default 'auto'
>  */
> ```

## Workflow

1. **Find the pipeline and the sibling.** Which docgen runs, which default tag it
   reads, and how the nearest component's props read.
2. **Categorize each prop** against the grammar table, and write the one-line
   summary in that category's shape.
3. **Add the second sentence only for a caller-visible constraint,** naming the
   symbol it involves.
4. **Move every default into the tag** the pipeline reads, and check the value
   against the code.
5. **Check the draft against the twelve patterns** literally.
6. **Document `children`,** and mark or hide the passthrough props the way the
   repository does.
7. **Verify it renders:** build the docs or Storybook and confirm the prop
   appears with its description and default. A prop missing from the table is a
   comment in the wrong place.
8. **Sweep the change** for prop docs it made inaccurate, including props you did
   not edit.
9. **Report** any prop you left undocumented and why, and any place the
   repository's convention differs from this guide.

## Sources

Prop TSDoc, in rough order of how closely to copy it:
[React Aria](https://github.com/adobe/react-spectrum) (`packages/@react-types/shared/src/`),
[Ariakit](https://github.com/ariakit/ariakit),
[Primer React](https://github.com/primer/react),
[MUI](https://github.com/mui/material-ui),
[Mantine](https://github.com/mantinedev/mantine),
[Polaris](https://github.com/Shopify/polaris),
[Carbon](https://github.com/carbon-design-system/carbon),
[Fluent UI](https://github.com/microsoft/fluentui).

Tooling that decides what survives:
[react-docgen-typescript](https://github.com/styleguidist/react-docgen-typescript),
[TSDoc](https://tsdoc.org),
[Storybook argTypes](https://storybook.js.org/docs/api/arg-types).

Fluent UI's narrative voice ("A button can show that it cannot be interacted
with") and Polaris's brand persona ("disallowing merchant interaction") are the
minority. React Aria, Primer, MUI, Mantine and Carbon are impersonal, and that is
the default here.

## Before you finish (checklist)

- [ ] Everything written passes the read-aloud test: a sentence a teammate would
      say, not one lifted from a design document. Nothing narrates one
      hypothetical instance, chains possessives, picks a verb for flavor where a
      plain one exists, or re-derives the mechanism in a trailing clause.
- [ ] American English in all prose. Spelling is preserved only in a quoted
      identifier, API name, string literal, or quoted text, in a new name joining a
      family the repository already spells the British way, and where a standard,
      schema, or protocol fixes it.
- [ ] Every public prop has a doc block immediately above it in the props type.
- [ ] `children` is documented, or the repository configures docgen to keep it.
- [ ] Every prop doc is one sentence, or two where the second states a real
      constraint. Only an accessibility obligation earns a third.
- [ ] Each prop follows its category's grammar: `Whether ...` for booleans,
      `Handler that is called when ...` for handlers, `(controlled)` and
      `(uncontrolled)` on a value pair.
- [ ] Every default is in the tag the repository's docgen reads, matches the
      code, and appears nowhere in prose.
- [ ] No doc restates the prop name, the type, or the component description.
- [ ] No scenario narration, no personification, no "you", no sensory framing.
- [ ] No ornamental contrast, no preamble, no hedging, no process residue.
- [ ] No implementation detail: no internal state, refs, memoization, or render
      behavior.
- [ ] Any counterfactual names the concrete failure and the symbol it affects.
- [ ] Every deprecation uses the tag and names the replacement.
- [ ] Constraints between props name the other prop in backticks.
- [ ] Accessibility obligations the caller inherits are stated on the prop that
      carries them.
- [ ] Hook docs give one line per returned value and name any required provider
      or parent.
- [ ] Code samples compile against the current props.
- [ ] The generated prop table was built and checked, and every prop appears with
      its description and default.
