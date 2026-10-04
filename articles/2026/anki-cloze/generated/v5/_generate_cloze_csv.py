from argparse import ArgumentParser
import html
from pathlib import Path
import re
import csv
from markdown import markdown
from mdn_preprocessor import normalize_mdn_markdown


CARDS = [
    (
        "MathML は HTML と同じ {{c1::構文}} を用いて要素と属性のツリーを表します。",
        "この記事では、単純な HTML 文書を使い、そこに MathML 数式を追加する方法を、いくつかの要素を紹介しながら見ていきます。",
        "{{ EmbedLiveSample('Inserting_formulas_in_HTML'",
    ),
    (
        "HTMLページに具体的な数式を配置するための要素は {{c1::<math>}} です。",
        "MathML は HTML と同じ構文を用いて要素と属性のツリーを表します。",
        "{{ EmbedLiveSample('Inserting_formulas_in_HTML'",
    ),
    (
        "MathMLの {{c1::<mfrac>}} 要素は、{{c1::分子（最初の子）}} と {{c1::分母（2 つ目の子）}} を持つ分数を指定します。",
        "`<mfrac>` 要素は分子（最初の子）と分母（2 つ目の子）を持つ分数を指定します。",
        "{{ EmbedLiveSample('Inserting_formulas_in_HTML'",
    ),
    (
        "数式を独立した行で中央揃えにするには、&lt;math&gt; 要素に {{c1::display=\"block\"}} 属性を付けます。",
        "### display 属性",
        "また、現れる微妙な変化にもお気づきでしょう。",
    ),
    (
        "&lt;math&gt; の display=\"block\" のとき、math-style の初期値は {{c1::normal}}、それ以外では {{c1::compact}} です。",
        "> [!NOTE]\n> 上述の外観の変化は、実際には",
        "## \\<mrow> 要素でのグループ化",
    ),
    (
        "LaTeXでは、インライン数式を <code>{{c1::$...$}}</code>、ディスプレイ数式を <code>{{c1::\\[...\\]}}</code> で区切ります。",
        "> [!NOTE]\n> これは LaTeX の _inline_ 数式",
        "> [!NOTE]\n> 上述の外観の変化は、実際には",
    ),
    (
        "MathMLの &lt;math&gt; 要素は {{c1::任意の数の子要素}} を格納し、それらを基本的に一列に並べて表示します。",
        "## \\<mrow> 要素でのグループ化",
        "### 演習: 入れ子になった式を書く",
    ),
    (
        "MathMLの &lt;mrow&gt; 要素は、サブツリーの {{c1::どこにでも}} 配置できる汎用コンテナーです。",
        "## \\<mrow> 要素でのグループ化",
        "### 演習: 入れ子になった式を書く",
    ),
    (
        "MathMLで「1 + 2 + 3」をエンコードするときは、数値に {{c1::<mn>}}、演算子に {{c1::<mo>}} 要素を使います。",
        "## \\<mrow> 要素でのグループ化",
        "### 演習: 入れ子になった式を書く",
    ),
    (
        "MathMLで複数の要素をグループ化する汎用コンテナーは {{c1::<mrow>}} です。",
        "## \\<mrow> 要素でのグループ化",
        "### 演習: 入れ子になった式を書く",
    ),
    (
        "「2 分の 1」足す「3 分の 2」という入れ子になった式は、2つの {{c1::<mfrac>}} を {{c1::<mo>+</mo>}} でつなぎます。",
        "### 演習: 入れ子になった式を書く",
        "{{ EmbedLiveSample('nested_expressions'",
    ),
    (
        "この入門で扱う主なMathML要素は、分数を表す {{c1::<mfrac>}}、グループ化を表す {{c1::<mrow>}}、そしてテキスト要素です。",
        "## まとめ",
        "## 関連情報",
    ),
]


def extract(source, start, end):
    start_index = source.index(start)
    end_index = source.index(end, start_index)
    return source[start_index:end_index].rstrip()


def build_rows(source):
    return [
        (
            markdown_to_html(normalize_mdn_markdown(prompt)),
            markdown_to_html(normalize_mdn_markdown(extract(source, start, end))),
        )
        for prompt, start, end in CARDS
    ]


CLOZE_RE = re.compile(r"\{\{(c\d+)::(.*?)\}\}", re.DOTALL)


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
    return converted


def main():
    parser = ArgumentParser(description="Create an Anki cloze CSV from a Markdown tutorial.")
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    source = args.source.read_text(encoding="utf-8")
    rows = build_rows(source)
    with args.output.open("w", encoding="utf-8", newline="") as output_file:
        csv.writer(output_file, quoting=csv.QUOTE_MINIMAL, lineterminator="\n").writerows(rows)

    with args.output.open("r", encoding="utf-8", newline="") as input_file:
        written_rows = list(csv.reader(input_file))
    assert len(written_rows) == len(rows)
    assert all(len(row) == 2 for row in written_rows)
    assert all("{{c1::" in row[0] for row in written_rows)
    print(f"rows: {len(written_rows)}")
    print(f"output: {args.output}")
    print("all_rows_have_two_fields: True")
    print("all_rows_have_cloze: True")


if __name__ == "__main__":
    main()
