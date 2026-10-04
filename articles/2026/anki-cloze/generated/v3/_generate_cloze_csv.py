from argparse import ArgumentParser
from pathlib import Path
import csv


CARDS = [
    (
        "MathML は HTML と同じ {{c1::構文}} を用いて要素と属性のツリーを表します。",
        "この記事では、単純な HTML 文書を使い、そこに MathML 数式を追加する方法を、いくつかの要素を紹介しながら見ていきます。",
        "{{ EmbedLiveSample('Inserting_formulas_in_HTML'",
    ),
    (
        "具体的な数式は {{c1::<math>}} 要素で表されます。",
        "MathML は HTML と同じ構文を用いて要素と属性のツリーを表します。",
        "{{ EmbedLiveSample('Inserting_formulas_in_HTML'",
    ),
    (
        "<mfrac> は {{c1::分子（最初の子）}} と {{c1::分母（2 つ目の子）}} を持つ分数を指定します。",
        "`<mfrac>` 要素は分子（最初の子）と分母（2 つ目の子）を持つ分数を指定します。",
        "{{ EmbedLiveSample('Inserting_formulas_in_HTML'",
    ),
    (
        "数式を独立した行で中央揃えにするには、<math> 要素に {{c1::display=\"block\"}} 属性を付けます。",
        "### display 属性",
        "また、現れる微妙な変化にもお気づきでしょう。",
    ),
    (
        "display=\"block\" のとき math-style の初期値は {{c1::normal}}、それ以外では {{c1::compact}} です。",
        "> [!NOTE]\n> 上述の外観の変化は、実際には",
        "## \\<mrow> 要素でのグループ化",
    ),
    (
        "LaTeX のインライン数式は {{c1::$...$}}、ディスプレイ数式は {{c1::\\[...\\]}} で区切られます。",
        "> [!NOTE]\n> これは LaTeX の _inline_ 数式",
        "> [!NOTE]\n> 上述の外観の変化は、実際には",
    ),
    (
        "<math> 要素は実際には {{c1::任意の数の子要素}} を格納でき、それらを基本的に一列に並べます。",
        "## \\<mrow> 要素でのグループ化",
        "### 演習: 入れ子になった式を書く",
    ),
    (
        "<mrow> は MathML サブツリーの {{c1::どこにでも}} 配置できる汎用コンテナーです。",
        "## \\<mrow> 要素でのグループ化",
        "### 演習: 入れ子になった式を書く",
    ),
    (
        "1 + 2 + 3 は MathML では {{c1::<mn> と <mo>}} 要素を並べてエンコードします。",
        "## \\<mrow> 要素でのグループ化",
        "### 演習: 入れ子になった式を書く",
    ),
    (
        "分数の分子と分母をグループ化する汎用コンテナーは {{c1::<mrow>}} です。",
        "## \\<mrow> 要素でのグループ化",
        "### 演習: 入れ子になった式を書く",
    ),
    (
        "入れ子になった式「2 分の 1」足す「3 分の 2」は、2つの {{c1::<mfrac>}} を {{c1::<mo>+</mo>}} でつなぎます。",
        "### 演習: 入れ子になった式を書く",
        "{{ EmbedLiveSample('nested_expressions'",
    ),
    (
        "この入門で扱う主な要素は {{c1::<mfrac>}}（分数）、{{c1::<mrow>}}（グループ化）、そしてテキスト要素です。",
        "## まとめ",
        "## 関連情報",
    ),
]


def extract(source, start, end):
    start_index = source.index(start)
    end_index = source.index(end, start_index)
    return source[start_index:end_index].rstrip()


def build_rows(source):
    return [(prompt, extract(source, start, end)) for prompt, start, end in CARDS]


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
