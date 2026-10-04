"""Generate an HTML-enabled Anki cloze CSV from a card-spec CSV.

Usage from the workspace root::

    python .agents/skills/anki-cloze-author/scripts/generate_cloze_csv.py \
        CARD_SPECS.csv SOURCE.md [OUTPUT.csv]

CARD_SPECS.csv has exactly three columns per row:

    prompt,extra_start_marker,extra_end_marker

The generator converts each prompt and source excerpt to HTML, writes Anki
headers, then invokes test_generate_cloze_csv.py against the output.
"""

from argparse import ArgumentParser
import csv
import html
import os
from pathlib import Path
import re
import subprocess
import sys

from markdown import markdown
from mdn_preprocessor import normalize_mdn_markdown


CLOZE_RE = re.compile(r"\{\{(c\d+)::(.*?)\}\}", re.DOTALL)
HEADER_COUNT = 5


def read_card_specs(card_specs_path):
    """Read prompt/start/end triples from the only hand-authored input file."""
    with card_specs_path.open(encoding="utf-8", newline="") as input_file:
        rows = list(csv.reader(input_file))

    specs = []
    for row_number, row in enumerate(rows, 1):
        if not row or all(not cell.strip() for cell in row):
            continue
        if len(row) != 3:
            raise ValueError(
                f"{card_specs_path}:{row_number} must have exactly 3 CSV fields "
                "(prompt, extra start, extra end); quote fields with commas or "
                "double quotes using RFC CSV syntax (\"\"), not backslash quotes"
            )
        normalized_row = tuple(
            cell.replace("\r\n", "\n")
            .replace("\r", "\n")
            .replace("\\n", "\n")
            .replace("\\\\<", "\\<")
            .replace("\\\\>", "\\>")
            for cell in row
        )
        specs.append(normalized_row)
    if not specs:
        raise ValueError(f"{card_specs_path} contains no card specifications")
    return specs


def extract(source, start, end, card_number=None):
    """Return the source section between exact markers, excluding the end marker."""
    label = f"card {card_number}: " if card_number is not None else ""
    start_index = source.find(start)
    if start_index < 0:
        raise ValueError(f"{label}extra start marker not found: {start!r}")
    end_index = source.find(end, start_index + len(start))
    if end_index < 0:
        raise ValueError(f"{label}extra end marker not found after start: {end!r}")
    return source[start_index:end_index].rstrip()


def markdown_to_html(text):
    """Convert Markdown to Anki HTML while preserving safe cloze markup."""
    clozes = []

    def protect_cloze(match):
        # Preprocessors may already escape code shown in <pre>. Decode first
        # so every cloze answer is escaped exactly once in the final HTML.
        escaped_answer = html.escape(html.unescape(match.group(2)), quote=False)
        clozes.append(f"{{{{{match.group(1)}::{escaped_answer}}}}}")
        return f"CLOZE_TOKEN_{len(clozes) - 1}"

    protected = CLOZE_RE.sub(protect_cloze, text)
    converted = markdown(protected, extensions=["extra", "fenced_code"])
    for index, cloze in enumerate(clozes):
        converted = converted.replace(f"CLOZE_TOKEN_{index}", cloze)
    return converted.replace(r"\[", r"\&#x200D;[").replace(r"\]", r"\&#x200D;]")


def build_rows(source, card_specs):
    """Convert card specs into HTML prompt/extra pairs."""
    rows = []
    for card_number, (prompt, start, end) in enumerate(card_specs, 1):
        extra = extract(source, start, end, card_number)
        rows.append(
            (
                markdown_to_html(normalize_mdn_markdown(prompt, render_samples=False)),
                markdown_to_html(normalize_mdn_markdown(extra)),
            )
        )
    return rows


def default_output_path(source_path):
    """Return the default sibling CSV path for a Markdown source."""
    return source_path.with_name(f"{source_path.stem}_cloze.csv")


def relative_source_tag(source_path):
    """Return a workspace-relative, POSIX-style tag for the source path."""
    return os.path.relpath(source_path.resolve(), Path.cwd().resolve()).replace(os.sep, "/")


def anki_headers(source_path):
    """Return the import headers expected by the configured Anki note type."""
    return [
        "#separator:Comma",
        "#html:true",
        "#notetype:穴埋め左寄せ",
        "#columns:テキスト,裏面追記",
        f"#tags:{relative_source_tag(source_path)}",
    ]


def write_csv(output_path, rows, source_path):
    """Write Anki headers and two-field rows with standard CSV escaping."""
    with output_path.open("w", encoding="utf-8", newline="") as output_file:
        output_file.write("\n".join(anki_headers(source_path)) + "\n")
        csv.writer(output_file, quoting=csv.QUOTE_MINIMAL, lineterminator="\n").writerows(rows)


def run_output_test(card_specs_path, source_path, output_path):
    """Run the companion validator so generation cannot silently skip tests."""
    test_script = Path(__file__).with_name("test_generate_cloze_csv.py")
    subprocess.run(
        [sys.executable, str(test_script), str(card_specs_path), str(source_path), str(output_path)],
        check=True,
    )


def main():
    """Parse inputs, generate the CSV, and automatically validate it."""
    parser = ArgumentParser(
        description="Generate and test an Anki cloze CSV from card specs and Markdown."
    )
    parser.add_argument("card_specs", type=Path, help="CSV with prompt,start-marker,end-marker")
    parser.add_argument("source", type=Path, help="Source Markdown file")
    parser.add_argument("output", type=Path, nargs="?", help="Output CSV (default: <source>_cloze.csv)")
    args = parser.parse_args()

    source = args.source.read_text(encoding="utf-8")
    card_specs = read_card_specs(args.card_specs)
    rows = build_rows(source, card_specs)
    output_path = args.output or default_output_path(args.source)
    write_csv(output_path, rows, args.source)
    run_output_test(args.card_specs, args.source, output_path)
    print(f"cards: {len(rows)}")
    print(f"output: {output_path}")
    print("validation: passed")


if __name__ == "__main__":
    main()
