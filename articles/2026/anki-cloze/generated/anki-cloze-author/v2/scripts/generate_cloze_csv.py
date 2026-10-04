"""Generate difficult, HTML-enabled Anki cloze notes from Markdown.

Usage from the workspace root::

    python .agents/skills/anki-cloze-author/scripts/generate_cloze_csv.py SOURCE.md [OUTPUT.csv]

To adapt this generator, replace ``CARDS`` with tuples of
``(prompt, extra_start_marker, extra_end_marker)``. The conversion, CSV
escaping, Anki headers, and validation below are intentionally reusable.
"""

from argparse import ArgumentParser
import html
import os
from pathlib import Path
import re
import csv
from markdown import markdown
from mdn_preprocessor import normalize_mdn_markdown


# Replace this source-specific card set for each new document. Keep prompts
# independent and prefer structural or code-reconstruction cards.
CARDS = [
    (
        "「2 分の 1」足す「3 分の 2」という入れ子になった式は、2つの {{c1::<mfrac>}} を {{c1::<mo>+</mo>}} でつなぎます。",
        "### 演習: 入れ子になった式を書く",
        "{{ EmbedLiveSample('nested_expressions'",
    ),
    (
        "`display=\"block\"` を指定したとき、math-style は {{c1::normal}} になり、指定しないと {{c2::compact}} になります。",
        "### display 属性",
        "## \\<mrow> 要素でのグループ化",
    ),
    (
        "LaTeXの {{c1::display}} 数式に対応するMathMLの指定は `display=\"{{c2::block}}\"` です。",
        "> [!NOTE]\n> これは LaTeX の _inline_ 数式",
        "## \\<mrow> 要素でのグループ化",
    ),
    (
        "「1 + 2 + 3」をMathMLで表すとき、子要素は {{c1::<mn>1</mn>}}、{{c2::<mo>+</mo>}}、{{c3::<mn>2</mn>}} の順に並び、最後に {{c4::<mn>3</mn>}} を置きます。",
        "## \\<mrow> 要素でのグループ化",
        "### 演習: 入れ子になった式を書く",
    ),
    (
        "分数 `(1 + 2) / 3` を表すとき、`<mfrac>` の分子は {{c1::<mrow>}} で囲み、分母には {{c2::<mn>3</mn>}} を置きます。",
        "`<mrow>` 要素は同様のレイアウトを行う汎用コンテナーですが、 MathML のサブツリーのどこにでも配置することができます。いくつかの要素をグループ化するのに便利です。",
        "### 演習: 入れ子になった式を書く",
    ),
    (
        "`(1 / 2) + (2 / 3)` を表すには、最上位の `<math>` の子として {{c1::2つの <mfrac>}} と {{c2::<mo>+</mo>}} を置きます。",
        "### 演習: 入れ子になった式を書く",
        "{{ EmbedLiveSample('nested_expressions'",
    ),
    (
        "`(1 + 2 + 3) / (4 + 5)` では、`<mfrac>` の分子と分母をそれぞれ {{c1::<mrow>}} でグループ化します。",
        "### 演習: 入れ子になった式を書く",
        "{{ EmbedLiveSample('nested_expressions'",
    ),
    (
        "`(1 / 4) / (2 + 3)` では、外側の `<mfrac>` の分子が {{c1::内側の <mfrac>}}、分母が {{c2::<mrow>}} になります。",
        "### 演習: 入れ子になった式を書く",
        "{{ EmbedLiveSample('nested_expressions'",
    ),
    (
        "次のMathMLで `(1 / 2) + (2 / 3)` を完成させてください。空欄には、分数・演算子・分数の順に {{c1::<mfrac>...</mfrac>}}、{{c2::<mo>+</mo>}}、{{c3::<mfrac>...</mfrac>}} を入れます。\n\n```html\n<math>\n  {{c1::<mfrac>\n    <mn>1</mn>\n    <mn>2</mn>\n  </mfrac>}}\n  {{c2::<mo>+</mo>}}\n  {{c3::<mfrac>\n    <mn>2</mn>\n    <mn>3</mn>\n  </mfrac>}}\n</math>\n```",
        "### 演習: 入れ子になった式を書く",
        "{{ EmbedLiveSample('nested_expressions'",
    ),
    (
        "次のMathMLで `(1 + 2 + 3) / (4 + 5)` を完成させてください。`<mfrac>` の2つの子は {{c1::<mrow>...</mrow>}} と {{c2::<mrow>...</mrow>}} です。\n\n```html\n<math>\n  <mfrac>\n    {{c1::<mrow>\n      <mn>1</mn>\n      <mo>+</mo>\n      <mn>2</mn>\n      <mo>+</mo>\n      <mn>3</mn>\n    </mrow>}}\n    {{c2::<mrow>\n      <mn>4</mn>\n      <mo>+</mo>\n      <mn>5</mn>\n    </mrow>}}\n  </mfrac>\n</math>\n```",
        "### 演習: 入れ子になった式を書く",
        "{{ EmbedLiveSample('nested_expressions'",
    ),
    (
        "次のMathMLで `(1 / 4) / (2 + 3)` を完成させてください。外側の分子には {{c1::<mfrac>...</mfrac>}}、分母には {{c2::<mrow>...</mrow>}} を置きます。\n\n```html\n<math>\n  <mfrac>\n    {{c1::<mfrac>\n      <mn>1</mn>\n      <mn>4</mn>\n    </mfrac>}}\n    {{c2::<mrow>\n      <mn>2</mn>\n      <mo>+</mo>\n      <mn>3</mn>\n    </mrow>}}\n  </mfrac>\n</math>\n```",
        "### 演習: 入れ子になった式を書く",
        "{{ EmbedLiveSample('nested_expressions'",
    ),
    (
        "`<mfrac>` の直下に `<mn>1</mn>`、`<mn>2</mn>`、`<mn>3</mn>` を置いたコードが不正になる理由は、{{c1::<mfrac>が分子と分母の2つの子だけを取る要素}}だからです。3つの項を分子にまとめるには {{c2::<mrow>}} が必要です。",
        "`<mfrac>` 要素は分子（最初の子）と分母（2 つ目の子）を持つ分数を指定します。",
        "## \\<mrow> 要素でのグループ化",
    ),
    (
        "次の2つの式の構造差を説明してください。`1 + 2 + 3` は `<math>` の {{c1::直接の子要素を順に並べる}} だけで表せますが、`(1 + 2) / 3` では分子を {{c2::<mrow>}} にまとめてから `<mfrac>` の子にします。",
        "## \\<mrow> 要素でのグループ化",
        "### 演習: 入れ子になった式を書く",
    ),
]


def extract(source, start, end):
    """Return the source section between exact markers, excluding the end marker."""
    start_index = source.index(start)
    end_index = source.index(end, start_index)
    return source[start_index:end_index].rstrip()


def build_rows(source):
    """Build HTML prompt/extra pairs from the configured card specifications."""
    return [
        (
            markdown_to_html(normalize_mdn_markdown(prompt)),
            markdown_to_html(normalize_mdn_markdown(extract(source, start, end))),
        )
        for prompt, start, end in CARDS
    ]


CLOZE_RE = re.compile(r"\{\{(c\d+)::(.*?)\}\}", re.DOTALL)


def markdown_to_html(text):
    """Convert Markdown to Anki HTML while preserving safe cloze markup."""
    clozes = []

    def protect_cloze(match):
        clozes.append(f"{{{{{match.group(1)}::{html.escape(match.group(2), quote=False)}}}}}")
        return f"CLOZE_TOKEN_{len(clozes) - 1}"

    protected = CLOZE_RE.sub(protect_cloze, text)
    protected = re.sub(
        r"^```([A-Za-z0-9_-]+)(?: [^\n]*)?$",
        r"```\1",
        protected,
        flags=re.MULTILINE,
    )
    converted = markdown(protected, extensions=["extra", "fenced_code"])
    for index, cloze in enumerate(clozes):
        converted = converted.replace(f"CLOZE_TOKEN_{index}", cloze)
    return converted.replace(r"\[", r"\&#x200D;[").replace(r"\]", r"\&#x200D;]")


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
    headers = anki_headers(source_path)
    with output_path.open("w", encoding="utf-8", newline="") as output_file:
        output_file.write("\n".join(headers) + "\n")
        csv.writer(output_file, quoting=csv.QUOTE_MINIMAL, lineterminator="\n").writerows(rows)


def main():
    """Parse source/output paths, generate notes, and validate the written CSV."""
    parser = ArgumentParser(description="Create an Anki cloze CSV from a Markdown tutorial.")
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path, nargs="?", help="CSV output path (default: <source>_cloze.csv)")
    args = parser.parse_args()

    source = args.source.read_text(encoding="utf-8")
    rows = build_rows(source)
    output_path = args.output or default_output_path(args.source)
    write_csv(output_path, rows, args.source)

    with output_path.open("r", encoding="utf-8", newline="") as input_file:
        written_rows = list(csv.reader(input_file))
    data_rows = written_rows[len(anki_headers(args.source)):]
    assert len(data_rows) == len(rows)
    assert all(len(row) == 2 for row in data_rows)
    assert all("{{c1::" in row[0] for row in data_rows)
    print(f"rows: {len(written_rows)}")
    print(f"output: {output_path}")
    print("all_rows_have_two_fields: True")
    print("all_rows_have_cloze: True")


if __name__ == "__main__":
    main()
