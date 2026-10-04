from argparse import ArgumentParser
import csv
import html
import os
from pathlib import Path
import re
import sys

from markdown import markdown

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from mdn_preprocessor import normalize_mdn_markdown


CARDS = [
    (
        "MathML のトークン要素を意味に応じて対応付けると、識別子は {{c1::<mi>}}、数値リテラルは {{c2::<mn>}}、演算子は {{c3::<mo>}}、任意の短いテキストは {{c4::<mtext>}} です。",
        "## ちょっとした意味づけ",
        "### 演習: トークン要素を認識する",
    ),
    (
        "MathML 数式中のテキストは、一般に {{c1::トークン要素と呼ばれるコンテナー}}の中に記載します。これは数式内のテキストの意味を表すためです。",
        "## ちょっとした意味づけ",
        "### 演習: トークン要素を認識する",
    ),
    (
        "絶対値の式 `|x| = x iff x ≥ 0` では、絶対値の各 `|` は {{c1::<mo>}}、変数 `x` は {{c2::<mi>}}、関係 `=` と `≥` も {{c3::<mo>}}、数値 `0` は {{c4::<mn>}} です。絶対値部分は {{c5::<mrow>}} でグループ化されています。",
        "### 演習: トークン要素を認識する",
        "## \\<mi> の自動的なイタリック化",
    ),
    (
        "`<mi>` の自動イタリック化は、{{c1::ラテン文字またはギリシャ文字の単一文字}}に適用されます。そのため `<mi>x</mi>` はイタリックになり、複数文字の `<mi>sin</mi>` は同じ規則ではイタリックになりません。",
        "## \\<mi> の自動的なイタリック化",
        "## \\<mi> の自動的なイタリック化の取り消し",
    ),
    (
        "`<mi>Γ</mi>` を直立体で表示したいときは、`<mi>` に {{c1::mathvariant=\"normal\"}} 属性を付けます。",
        "## \\<mi> の自動的なイタリック化の取り消し",
        "## \\<mo> の演算子プロパティ",
    ),
    (
        "`<mo>` の既定プロパティは、演算子辞書に基づき、コンテナー内での位置である {{c1::前置き・中間・後置き}} とコンテンツに応じて決まります。したがって同じ `+` でも前置と中間で空間が異なります。",
        "## \\<mo> の演算子プロパティ",
        "### 違いを見つける",
    ),
    (
        "数学記号を含む HTML 文書では、文字コードとして {{c1::UTF-8}} を指定し、数式記号の表示には {{c2::Latin Modern Math}} のような数学フォントを指定します。",
        "## 数式のための Unicode 文字",
        "## ちょっとした意味づけ",
    ),
    (
        "テキストだけの `∀A∊𝔰𝔩(n,𝔽),TrA=0` を MathML に書き換えると、量化記号や関係記号は {{c1::<mo>}}、単一の変数 `A` や `n` は {{c2::<mi>}}、数値 `0` は {{c3::<mn>}} になります。複数文字の `𝔰𝔩` と `Tr` はそれぞれ1つの `<mi>` に入ります。",
        "### 違いを見つける",
        "### 伸縮演算子を確認",
    ),
    (
        "`|1/x| = 1/|x| = 1/x` の例で縦方向に伸縮するのは、最初の2つの {{c1::<mo>|</mo>}} です。これらは子孫の {{c2::<mfrac>}} の高さに合わせて伸縮します。",
        "### 伸縮演算子を確認",
        "## まとめ",
    ),
    (
        "次の MathML で `|x| = x iff x ≥ 0` を表すとき、絶対値の内側の `x` は {{c1::<mi>x</mi>}}、等号は {{c2::<mo>=</mo>}}、条件の `0` は {{c3::<mn>0</mn>}} として記述します。",
        "最後に、 MathML のソースを読んで",
        "> [!NOTE]\n> 指定されたテキストコンテンツ",
    ),
    (
        "テキストコンテナーの選択に迷っても、一般にはすべてのトークン要素が同じようにレンダリングされます。ただし {{c1::<mi>}} と {{c2::<mo>}} には自動イタリック化や演算子プロパティという特別な機能があります。",
        "> [!NOTE]\n> 指定されたテキストコンテンツ",
        "## \\<mi> の自動的なイタリック化",
    ),
    (
        "伸縮演算子を正しく表示するには、一般に {{c1::特別な数学フォント}} が必要です。ブラウザーの既定フォントだけに依存すると、縦方向の伸縮用グリフがない場合があります。",
        "> [!WARNING]\n> 伸縮できるようにするには",
        "## まとめ",
    ),
]


CLOZE_RE = re.compile(r"\{\{(c\d+)::(.*?)\}\}", re.DOTALL)


def extract(source, start, end):
    start_index = source.index(start)
    end_index = source.index(end, start_index)
    return source[start_index:end_index].rstrip()


def markdown_to_html(text):
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


def build_rows(source):
    return [
        (
            markdown_to_html(normalize_mdn_markdown(prompt)),
            markdown_to_html(normalize_mdn_markdown(extract(source, start, end))),
        )
        for prompt, start, end in CARDS
    ]


def default_output_path(source_path):
    return source_path.with_name(f"{source_path.stem}_cloze.csv")


def relative_source_tag(source_path):
    return os.path.relpath(source_path.resolve(), Path.cwd().resolve()).replace(os.sep, "/")


def anki_headers(source_path):
    return [
        "#separator:Comma",
        "#html:true",
        "#notetype:穴埋め左寄せ",
        "#columns:テキスト,裏面追記",
        f"#tags:{relative_source_tag(source_path)}",
    ]


def write_csv(output_path, rows, source_path):
    with output_path.open("w", encoding="utf-8", newline="") as output_file:
        output_file.write("\n".join(anki_headers(source_path)) + "\n")
        csv.writer(output_file, quoting=csv.QUOTE_MINIMAL, lineterminator="\n").writerows(rows)


def main():
    parser = ArgumentParser(description="Create Anki cloze cards for the MathML text container tutorial.")
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
    print(f"rows: {len(rows)}")
    print(f"output: {output_path}")
    print("all_rows_have_two_fields: True")
    print("all_rows_have_cloze: True")


if __name__ == "__main__":
    main()