# Anki Cloze Generator

このフォルダーが、このワークスペースにおける穴埋めカード生成コードの正本です。`mathml/` 内の `_generate_cloze_csv.py` は過去の資料専用スナップショットなので、新しい資料では使いません。

## 新しく作るファイル

新しい資料ごとに作成・編集するファイルは、カード仕様CSVの1種類だけです。1行に次の3フィールドを入れます。

1. 穴埋め問題。問題単体で意味が通る文章にし、難しい問題では `c1`, `c2`, `c3` を使って複数箇所を関連づける。
2. `extra` に収録する原文の切り抜き開始文字列。
3. `extra` に収録する原文の切り抜き終了文字列。

CSVなので、カンマ・改行・ダブルクォートを含むフィールドは必ずCSVとして引用します。特にコードを含む問題文は、表計算ソフトやPythonの `csv.writer` で作成してください。

セル内の改行は実改行でも文字列 `\\n` でも入力できます。生成器が読み込み時に実改行へ正規化するため、コードフェンスを正しくMarkdownとして処理できます。

例:

```csv
"`(1 + 2) / 3` の分子は {{c1::<mrow>}} で囲み、分母は {{c2::<mn>3</mn>}} にする。","`<mrow>` 要素は","### 演習:"
```

## 実行方法

ワークスペースのルートから、カード仕様CSVと原文Markdownを渡します。

```powershell
python .agents\skills\anki-cloze-author\scripts\generate_cloze_csv.py `
  mathml\getting_started_cards.csv `
  mathml\getting_started.md `
  mathml\getting_started_cloze.csv
```

出力引数を省略すると、原文と同じフォルダーに `<原文のstem>_cloze.csv` を作ります。

生成器は次の処理を自動で行います。

1. カード仕様CSVを読み、各行の3フィールドを検証する。
2. 原文から開始文字列と終了文字列の間を抽出する。
3. MDN固有記法を前処理する。
4. 問題文とextraをMarkdownからHTMLへ変換する。
5. cloze内のHTMLタグをエスケープし、MathJax対策を適用する。
6. Ankiヘッダー付きCSVを書き出す。
7. `test_generate_cloze_csv.py` を自動実行し、出力を検証する。

問題文にコードフェンスがある場合は、穴埋め途中の不完全なHTML/MathMLを
描画せず、`<pre><code>` のコード表示だけにします。extra側の完全な原文コードは、
コード表示とレンダリング結果の両方を出力します。

## ファイルの役割

- `generate_cloze_csv.py`: カード仕様CSVと原文から出力CSVを生成し、テストを起動する。
- `mdn_preprocessor.py`: MDNのマクロ、`\\<tag>`、live-sample、HTMLコード例を処理する。
- `test_generate_cloze_csv.py`: 生成されたCSVをカード仕様・原文・難易度条件と照合する。

## テスト単体の実行

通常は生成器が自動実行します。単体で実行する場合は次の形式です。

```powershell
python .agents\skills\anki-cloze-author\scripts\test_generate_cloze_csv.py `
  mathml\getting_started_cards.csv `
  mathml\getting_started.md `
  mathml\getting_started_cloze.csv
```

テストは、2フィールド構成、clozeタグ、HTML化、原文マーカー、MDNマクロ除去、MathJax対策、複数clozeまたはコード再構成による難易度を検証します。
