"""Generate Anki cloze notes for the MathML text-container tutorial."""

from argparse import ArgumentParser
import importlib.util
from pathlib import Path
import sys


SKILL_SCRIPTS = Path(__file__).parents[2] / ".agents" / "skills" / "anki-cloze-author" / "scripts"
sys.path.insert(0, str(SKILL_SCRIPTS))
SPEC = importlib.util.spec_from_file_location(
    "anki_cloze_pipeline", SKILL_SCRIPTS / "generate_cloze_csv.py"
)
PIPELINE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(PIPELINE)

anki_headers = PIPELINE.anki_headers
default_output_path = PIPELINE.default_output_path
markdown_to_html = PIPELINE.markdown_to_html
normalize_mdn_markdown = PIPELINE.normalize_mdn_markdown
write_csv = PIPELINE.write_csv


CARDS = [
    (
        "MathML のトークン要素を、用途とともに対応付けてください。識別子は {{c1::<mi>}}、数値リテラルは {{c2::<mn>}}、演算子は {{c3::<mo>}}、短い任意テキストは {{c4::<mtext>}} です。",
        "## ちょっとした意味づけ",
        "### 演習: トークン要素を認識する",
    ),
    (
        "`|x| = x iff x ≥ 0` の MathML 構造を完成させてください。絶対値部分は {{c1::<mrow>...</mrow>}}、等号と不等号は {{c2::<mo>}}、変数は {{c3::<mi>}}、数値は {{c4::<mn>}} で表します。",
        "### 演習: トークン要素を認識する",
        "## \\<mi> の自動的なイタリック化",
    ),
    (
        "次の2つの MathML 要素のうち、単一のラテン文字またはギリシャ文字を自動的にイタリック化するのは {{c1::<mi>x</mi>}} です。複数文字の関数名 `sin` は {{c2::<mi>sin</mi>}} のように書いても同じ自動変換になりません。",
        "## \\<mi> の自動的なイタリック化",
        "## \\<mi> の自動的なイタリック化の取り消し",
    ),
    (
        "`Γ` を通常の立体で表示する MathML を完成させてください。既定の要素は `<mi>Γ</mi>`、自動イタリック化を取り消す要素は {{c1::<mi mathvariant=\"normal\">Γ</mi>}} です。",
        "## \\<mi> の自動的なイタリック化の取り消し",
        "## \\<mo> の演算子プロパティ",
    ),
    (
        "`+` の前後の空間の違いを説明してください。`+i` の `+` は {{c1::前置演算子}}、`j+i` の `+` は {{c2::中間演算子}} なので、後者には前者より空間があります。",
        "## \\<mo> の演算子プロパティ",
        "### 違いを見つける",
    ),
    (
        "テキストだけの `∀A∊𝔰𝔩(n,𝔽),TrA=0` を MathML に分解する場合、変数・数値は {{c1::<mi> または <mn>}}、関係記号や区切り記号は {{c2::<mo>}}、入れ子のまとまりは {{c3::<mrow>}} にします。",
        "### 違いを見つける",
        "### 伸縮演算子を確認",
    ),
    (
        "次の式で、分数の高さに応じて垂直方向に伸縮する `|` は、最初の {{c1::<mo>|</mo>}} とその対になる {{c2::<mo>|</mo>}} です。伸縮しない `|` と区別するには、子孫に `<mfrac>` があるかを確認します。",
        "### 伸縮演算子を確認",
        "## まとめ",
    ),
    (
        "`|x| = x iff x ≥ 0` の式で、`<mtext>` が担当するのは {{c1::`iff` のような数式中の短い語}} であり、`x`、`≥`、`0` はそれぞれ {{c2::<mi>}}、{{c3::<mo>}}、{{c4::<mn>}} です。",
        "## まとめ",
        "## 関連情報",
    ),
    (
        "MathML のトークン要素について、`<mi>` は {{c1::識別子}}、`<mn>` は {{c2::数値}}、`<mo>` は {{c3::演算子}}、`<mtext>` は {{c4::汎用テキスト}}を表します。さらに `<mi>` と `<mo>` には {{c5::自動イタリック化や演算子プロパティ}} という特別な挙動があります。",
        "## まとめ",
        "## 関連情報",
    ),
]


def extract(source, start, end):
    start_index = source.index(start)
    end_index = source.index(end, start_index)
    return source[start_index:end_index].rstrip()


def build_rows(source):
    rows = []
    for prompt, extra_start, extra_end in CARDS:
        rows.append(
            (
                markdown_to_html(normalize_mdn_markdown(prompt)),
                markdown_to_html(
                    normalize_mdn_markdown(extract(source, extra_start, extra_end))
                ),
            )
        )
    return rows


def main():
    parser = ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path, nargs="?")
    args = parser.parse_args()
    source = args.source.read_text(encoding="utf-8")
    rows = build_rows(source)
    output = args.output or default_output_path(args.source)
    write_csv(output, rows, args.source)
    assert len(rows) == len(CARDS)
    assert all(len(row) == 2 and "{{c1::" in row[0] for row in rows)
    assert all("EmbedLiveSample" not in field for row in rows for field in row)
    assert all("{{PreviousMenuNext" not in field for row in rows for field in row)
    print(f"rows: {len(rows)}")
    print(f"output: {output}")
    print(f"headers: {anki_headers(args.source)}")


if __name__ == "__main__":
    main()