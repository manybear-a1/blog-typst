# Anki Cloze Generator Scripts

These are the reusable scripts for this workspace. Use these files instead of any generator inside a source folder such as `mathml/`.

## Files

- `generate_cloze_csv.py`: reads a Markdown source, converts card prompts and contextual excerpts to Anki HTML, and writes a two-column cloze CSV.
- `mdn_preprocessor.py`: optional MDN-specific normalization. It handles escaped angle brackets, MDN macros, live-sample fences, and code-plus-rendered-result blocks.
- `test_generate_cloze_csv.py`: regression tests for the generator. Set `ANKI_CLOZE_SOURCE` to a source Markdown file before running the source-dependent test.

## Input And Output

Run the generator from the workspace root or pass absolute paths:

```powershell
python .agents\skills\anki-cloze-author\scripts\generate_cloze_csv.py SOURCE.md [OUTPUT.csv]
```

When `OUTPUT.csv` is omitted, the output is placed next to the source with the source stem plus `_cloze.csv`.

The generator's `CARDS` constant is the source-specific part. Each entry is:

```python
(prompt, extra_start_marker, extra_end_marker)
```

Copy the generator for a new document, replace `CARDS` with independent, difficult prompts, and keep the conversion and CSV-writing functions unchanged unless the note type requires it. Each `extra` range should include enough explanation or code for later review.

## Processing Pipeline

1. Read the source as UTF-8.
2. Extract each contextual `extra` range using its start and end markers.
3. Normalize MDN syntax with `mdn_preprocessor.py`.
4. Protect cloze expressions and HTML-escape their answers.
5. Convert Markdown to HTML with Python-Markdown.
6. Add the MathJax guard to `\\[` and `\\]` delimiters.
7. Write Anki headers followed by CSV rows using Python's `csv` module.
8. Re-read the CSV and validate its field count and cloze tags.

## Tests

From the workspace root:

```powershell
$env:ANKI_CLOZE_SOURCE = "mathml\getting_started.md"
python -m unittest discover -s .agents\skills\anki-cloze-author\scripts -p "test_*.py" -v
Remove-Item Env:ANKI_CLOZE_SOURCE
```

The tests should be adapted when the card set for a new source changes. Keep assertions for independent HTML prompts, multiple clozes, contextual extras, and the removal of source-specific MDN macros.
