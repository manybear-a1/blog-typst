---
name: anki-cloze-author
description: 'Create difficult, self-contained Anki cloze notes from Markdown or MDN-style documents. Use when converting technical documentation into HTML-enabled cloze CSV files, designing multi-cloze structure questions, handling Markdown/MDN syntax, preserving code examples, or adding regression tests.'
argument-hint: 'Source Markdown file and desired learning scope'
user-invocable: true
---

# Anki Cloze Author

Create Anki cloze notes from technical documents while keeping each note independently reviewable and suitable for Anki's HTML fields.

## When To Use

Use this skill when the user asks to:

- turn a Markdown, MDN, or technical document into Anki cloze cards;
- produce a CSV for Anki import with HTML fields;
- make cards harder by testing structure, reconstruction, comparison, or diagnosis;
- preserve code examples and rendered HTML/MathML in the extra field;
- create a repeatable generator and tests for future source documents.

## Workflow

## Canonical Implementation

This workspace-local directory is the only canonical implementation:

`.agents/skills/anki-cloze-author/scripts/`

Read [the script guide](./scripts/README.md) before running or adapting code.
Do not select `mathml/_generate_cloze_csv.py`; that file is a source-specific
working copy, not the reusable skill implementation.

The reusable implementation is bundled in:

- [generator](./scripts/generate_cloze_csv.py)
- [MDN preprocessor](./scripts/mdn_preprocessor.py)
- [regression test template](./scripts/test_generate_cloze_csv.py)

For a new document, do not copy or edit the Python generator. Create one card
specification CSV and pass it to the bundled generator. This prevents a source
folder's old working script from being selected and makes the input contract
explicit.

### 1. Inspect The Source

1. Read the source and identify its conceptual sections, code examples, exercises, and summaries.
2. Check whether the document has source-specific syntax such as MDN macros, escaped angle brackets, special code-fence labels, or live-sample directives.
3. Inspect existing project conventions, dependencies, generators, and tests before editing.
4. State a local hypothesis about the source structure and choose a cheap validation check before making the first edit.

### 2. Separate Source-Specific Preprocessing

Keep document-specific normalization separate from the generic card generator.

For MDN-style input, use a separate preprocessor module to:

- convert `\\<tag>` and `\\>` notation into HTML-safe text;
- remove navigation and embedding macros such as `NextMenu` and `EmbedLiveSample`;
- normalize `live-sample` code fences;
- preserve the code and add a rendered-result block for HTML/MathML examples;
- convert ordinary HTML code fences to the same code-plus-rendered-result representation when rendering is useful.

Do not put MDN rules into the generic Markdown-to-HTML function. Add a new preprocessor for another document dialect.

### 3. Create The Card Specification CSV

The card specification CSV is the only new hand-authored file. Every row has
exactly three fields, in this order:

1. A complete cloze prompt.
2. The exact source substring where `extra` starts.
3. The exact source substring where `extra` ends.

Use a real CSV writer or a spreadsheet that preserves CSV quoting. Quote fields
containing commas, line breaks, or double quotes. Do not add a header row unless
the generator is explicitly changed to support one.

Run the canonical script from the workspace root:

```powershell
python .agents\skills\anki-cloze-author\scripts\generate_cloze_csv.py `
	CARD_SPECS.csv SOURCE.md [OUTPUT.csv]
```

The generator automatically runs `test_generate_cloze_csv.py` after writing the
output. Do not invoke `mathml/_generate_cloze_csv.py` for new material.

### 4. Design Independent Cards

Each CSV data row must make sense without reading a previous row.

For every card, define:

- a complete prompt containing enough context to answer it;
- one or more cloze deletions;
- an extra excerpt covering the relevant explanation, example, or exercise, not merely the answer sentence.

Prefer higher-value cards over one-word recall:

- reconstruct a code tree from a mathematical expression;
- identify the correct parent-child structure;
- complete a partial HTML/MathML example;
- compare two similar representations;
- diagnose why a structure is invalid;
- infer where grouping is required or unnecessary;
- use multiple clozes (`c1`, `c2`, `c3`, ...) when the relationship between parts matters.

Remove cards that only ask for isolated element names when the source supports a structural question instead.

#### Difficulty Gate

Before writing the CSV, classify every candidate card. Reject a card if its
answer is only one obvious term and the source supports a relationship or
reconstruction question. The final set must contain:

- at least half structural, comparative, diagnostic, or code-reconstruction cards;
- multiple clozes on cards where several parts must be related;
- at least one card that reconstructs or completes a non-trivial code tree when
	the source contains code examples;
- no return to the original easy set merely because it is easier to generate.

If a source is too short to meet these thresholds, report that limitation
instead of silently lowering the difficulty.

A useful source-specific card specification is:

```python
(prompt, extra_start_marker, extra_end_marker)
```

Extract the extra range mechanically from the source and fail loudly if either marker is missing.

### 5. Convert Markdown To Anki HTML

Use a Markdown conversion library such as Python-Markdown. Do not hand-convert Markdown syntax with ad hoc string replacements.

Before conversion:

1. Protect cloze expressions with placeholders.
2. HTML-escape cloze answers so values such as `<mfrac>` remain visible text inside Anki clozes.
3. Convert Markdown with the required extensions, including fenced code.
4. Restore the protected clozes.

Do not render a prompt's incomplete code block. Show it as escaped
`<pre><code>` only. Render code examples in `extra` only when they are complete;
otherwise an incomplete MathML tree can suppress or corrupt visible math.

For Anki MathJax safety, do not rely on `<code>` alone. Insert the zero-width entity `&#x200D;` into display delimiters after conversion:

```text
\\[  ->  \\&#x200D;[
\\]  ->  \\&#x200D;]
```

Keep the backslash and the delimiter intact while placing `&#x200D;` between them. Verify that no unprotected `\\[` or `\\]` remains.

### 6. Write The Anki CSV

Use Python's `csv` module with UTF-8 and `newline=""`; never manually escape commas, quotes, or embedded newlines.

The output must begin with Anki headers. Use the project's requested note type and column names; the standard pattern from this workflow is:

```text
#separator:Comma
#html:true
#notetype:穴埋め左寄せ
#columns:テキスト,裏面追記
#tags:<relative-source-path>
```

Use `<source stem>_cloze.csv` when the output argument is omitted. Normalize the source tag to a workspace-relative POSIX-style path.

### 7. Test And Validate

The generator automatically invokes the companion validator. The validator
must test:

- default output path calculation;
- exact Anki header lines and relative source tag;
- two CSV fields per data row;
- every prompt contains at least one cloze;
- source extraction produces the expected number of cards;
- all prompts are self-contained HTML paragraphs or intentionally structured HTML;
- source-specific macros and Markdown markers are absent from output;
- code examples have paired rendered-result blocks where required;
- MathJax delimiters are protected;
- multi-cloze or code-reconstruction cards meet the difficulty gate.

Run the generator with the card-spec CSV and source first. It must print
`validation: passed`. Inspect representative CSV rows, especially multiline
code examples and rows with multiple clozes. If validation fails, fix the
card-spec CSV rather than patching the generated output.

When validating difficulty, print or inspect every generated prompt and verify
that the easy definition-only cards were actually removed. Test the bundled
script from its canonical directory, not from a source document's folder.

## Completion Criteria

The task is complete only when:

- the CSV is generated without manual escaping;
- each note stands alone during review;
- the extra field is a useful contextual excerpt;
- difficult cards test relationships or reconstruction rather than only definitions;
- Markdown and source-specific syntax are converted to safe Anki HTML;
- code examples and rendered results are preserved where appropriate;
- Anki headers and relative tags are present;
- the generator and regression tests pass;
- the reusable generator does not contain rules that belong to one source dialect.
