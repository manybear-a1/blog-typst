---
name: anki-cloze-author
description: 'Create difficult, self-contained Anki cloze notes from Markdown documents. Use when converting technical documentation into HTML-enabled cloze CSV files, designing multi-cloze structure questions, handling Markdown syntax, preserving code examples, or adding regression tests.'
argument-hint: 'Source Markdown file and desired learning scope'
user-invocable: true
---

# Anki Cloze Author

Create Anki cloze notes from technical documents while keeping each note independently reviewable and suitable for Anki's HTML fields.

## When To Use

Use this skill when the user asks to:

- turn a Markdown, or technical document into Anki cloze cards;
- produce a CSV for Anki import with HTML fields;
- make cards harder by testing structure, reconstruction, comparison, or diagnosis;
- preserve code examples and rendered HTML/MathML in the extra field;

## Workflow

### Implementation

Use only the workspace-local scripts below:

- `./scripts/generate_cloze_csv.py`
- `./scripts/mdn_preprocessor.py`
- `./scripts/test_generate_cloze_csv.py`
- `./scripts/README.md`

### 1. Inspect The Source

1. Read the source and identify its conceptual sections, code examples, exercises, and summaries.

### 2. Create The Card Specification CSV

The card specification CSV is the only new hand-authored file. Every row has exactly three fields, in this order:

1. A complete cloze prompt.
2. The exact source substring where `extra` starts.
3. The exact source substring where `extra` ends.

Use a real CSV writer or a spreadsheet that preserves CSV quoting. Quote fields
containing commas, line breaks, or double quotes. Do not add a header row unless the generator is explicitly changed to support one.

Use RFC CSV escaping: double an embedded quote as `""`; never use `\"` as a
CSV escape. Code-block prompts may contain real newlines or the literal `\n`;
the generator normalizes both.

### 3. Design Independent Cards

Each CSV data row must make sense without reading a previous row.

For every card, define:

- a complete prompt containing enough context to answer it;
- one or more cloze deletions;
- an extra excerpt covering the relevant explanation, example, or exercise, not merely the answer sentence.

Apply Cherry's three card-creation rules to every candidate:

1. **Make the test concise and precise.** State exactly what the learner must
	recall. Use a cloze hint when it clarifies the requested answer type or
	relation, but never when it reveals the answer. Remove vague prompts,
	implied question-answer pairs, unnecessary prose, and grammatical cues that
	give away the cloze.
2. **Make the test challenging and encompassing.** Prefer recall, reconstruction,
	comparison, diagnosis, application, or code completion over recognition of a
	single term. Keep closely related parts together when their relationship is
	part of what should be remembered; use multiple clozes or an all-at-once
	cloze when that tests the structure better. Add smaller supporting clozes
	only when the large, meaningful test remains.
3. **Put teaching context on the back.** Use `extra` as reference material for
	a future self who may have forgotten the explanation: include definitions,
	reasoning, examples, derivations, comparisons, common confusions, relevant
	code, and source links when available. Keep the prompt answer-focused, while
	allowing `extra` to be as detailed as the source warrants.

Remove cards that only ask for isolated element names when the source supports a structural question instead.

#### Difficulty Gate

Before writing the CSV, classify every candidate card. Reject a card if its answer is only one obvious term and the source supports a relationship or
reconstruction question. The final set must contain:

- at least half structural, comparative, diagnostic, or code-reconstruction cards;
- multiple clozes when several parts must be related;
- concise, precise wording with no accidental answer cues;
- enough scope to test the intended relationship, not just an easy fragment;
- useful explanatory context in `extra`, including at least one example or
  rationale when the source provides one;
- no return to the original easy set merely because it is easier to generate.

Also check prerequisites and transfer: do not make a card depend on an
undefined term when the source provides the prerequisite context, and do not
use a special-case example as if it represented the general rule. When a
procedure or skill is involved, the card should test executing or selecting
the procedure, while `extra` should show a representative worked example; the
card does not replace practice outside Anki.

If a source is too short to meet these thresholds, report that limitation
instead of silently lowering the difficulty.

### 4. Convert And Generate

Run the script from the workspace root:

```powershell
python .agents\skills\anki-cloze-author\scripts\generate_cloze_csv.py `
	CARD_SPECS.csv SOURCE.md [OUTPUT.csv]
```

The generator reads the three CSV fields, extracts the exact source range, applies preprocessing, converts Markdown to HTML, protects clozes, writes Anki headers, and automatically invokes the validator. A successful run
must end with `validation: passed`.

Incomplete prompt code is shown as `<pre><code>` only. Complete code in `extra` may also receive a rendered-result block, so incomplete MathML is never sent to
the MathML renderer.

## Completion Criteria

The task is complete only when:

- each note stands alone during review;
- the extra field is a useful contextual excerpt;
- difficult cards test relationships or reconstruction rather than only definitions;
- the generator and regression tests pass;
