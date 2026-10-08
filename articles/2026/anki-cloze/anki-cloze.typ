#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "/template/template.typ": *
#show: show_blog_with_typst
#show: codly-init.with()
#show link: set text(fill: blue)
#codly(languages: codly-languages)

#let prompt_box(prompt) = {
  block(breakable: true, stroke: black, inset: 1em)[
    プロンプト:

    #prompt
  ]
}
#let answer_box(answer) = {
  block(breakable: true, fill: white.darken(2.5%), inset: 1em)[
    回答:

    #answer
  ]
}

= 穴埋め問題を作らせる
- 使用したAI:GPT-5.6-Luna(Github Copilot Chat)

== まずはテスト
とりあえず、穴埋め問題を作らせるテストをしてみる。
作らせる題材にするのは、#link("https://github.com/mdn/translated-content/blob/4d60048518bfbe8ee8ffa0c89a2f141983f88c1a/files/ja/web/mathml/tutorials/for_beginners/getting_started/index.md")[MDN-MathML を始めよう] としてみる。（ちょうど自分が勉強していた。）

#prompt_box("getting_started.mdをankiの穴埋め問題にして")

で、できたのがこれ。
#codly-range(1, end: 15)
#answer_box()[
  #raw(read("generated/v1/getting_started_cloze.md"), lang: "markdown", block: true)
]
どうやって取り込めと？　あと、せっかく資料を渡したのに一から書き直さないでくれ。それだったら資料を渡さずに直接「mathmlの穴埋め問題を作れ」と言うよ！

まぁ、なにはともあれ、穴埋めのフォーマットは知っていることは確認できたが、どうもあまり知識がなさそうなので、公式ドキュメントの#link("https://github.com/ankitects/anki-manual/blob/00c7a9b31c0cf967ec44be74b6a56e188db5c311/src/importing/text-files.md")[importのページ]を読ませて再挑戦。（プロンプトは同じ）
#answer_box()[
  #codly-range(1, end: 5)
  #raw(read("generated/v1/getting_started_cloze.txt"), lang: "txt", block: true)
]
今度はtxtファイルで正しい形式で出力してくれたので、Ankiに取り込める。が、やはり文章を一から書き直してしまっている。あと、txtファイルではなくcsvファイルで出力してくれた方がAnkiに取り込みやすいし、後から編集もしやすい。（なぜか公式ドキュメントではtxtになっているが）というわけで、プロンプトを変えて再度挑戦。

#prompt_box(
  "getting_started.mdをankiの穴埋め問題にして。
- 原文をそのまま穴埋めにすること
- エスケープ処理はpythonを使って機械的に行うこと
- 出力ファイルはcsv形式にすること",
)
#answer_box()[
  （筆者による抜粋）変換単位は、原文全体を 1 件の Cloze ノートにする形にします。本文の説明文・コード例・見出しは残し、MathML の主要要素名と display / CSS プロパティ名を原文の該当箇所だけ Cloze 化します。次に Python の re と csv.writer で CSV を生成し、読み戻して列数・Cloze 数・改行保持を検査します。
  #codly-range(1, end: 12)
  ```shell
    @'
  from pathlib import Path
  import csv
  import re

  source_path = Path(r"c:\Users\takum\Desktop\anki\mathml\getting_started.md")
  output_path = Path(r"c:\Users\takum\Desktop\anki\mathml\getting_started_cloze.csv")
  text = source_path.read_text(encoding="utf-8")
  tokens = [
      "<math>", "</math>", "<mfrac>", "</mfrac>", "<mrow>", "</mrow>",
      "<mn>", "</mn>", "<mo>", "</mo>", 'display="block"', "math-style", "math-depth",
  ]
  token_pattern = re.compile("|".join(re.escape(token) for token in tokens))
  cloze_number = 0

  def replace_token(match):
      global cloze_number
      cloze_number += 1
      return "{{{{c{}::{}}}}}".format(cloze_number, match.group(0))

  converted_text = token_pattern.sub(replace_token, text)
  with output_path.open("w", encoding="utf-8", newline="") as output_file:
      writer = csv.writer(output_file, lineterminator="\n", quoting=csv.QUOTE_MINIMAL)
      writer.writerow(["Text", "Extra"])
      writer.writerow([converted_text, "原文全体を保持し、MathML 要素名と関連プロパティを穴埋め化"])

  with output_path.open("r", encoding="utf-8", newline="") as input_file:
      rows = list(csv.reader(input_file))

  print("rows:", len(rows))
  print("field_counts:", [len(row) for row in rows])
  print("source_characters:", len(text))
  print("cloze_markers:", len(re.findall(r"\{\{c\d+::", converted_text)))
  print("embedded_newlines:", "\n" in rows[1][0])
  print("first_cloze:", re.search(r"\{\{c\d+::.*?\}\}", converted_text).group(0))
  print("output:", output_path)
  '@ | python -
  ```
  （省略）

  122 個の Cloze マーカーが生成され、CSV は 2 行・各 2 列として読み戻せています。

  #codly-range(1, end: 12)
  #raw(read("generated/v1/getting_started_cloze.csv"), lang: "csv", block: true)
  （中略）
  #codly-range(99, end: 150)
  #raw(read("generated/v1/getting_started_cloze.csv"), lang: "csv", block: true)
  （中略）
  #codly-range(165, end: 169)
  #raw(read("generated/v1/getting_started_cloze.csv"), lang: "csv", block: true)
]


どうしてそうなった？　原文をそのままってそういう意味じゃねぇよ！！！　あと、同じ単語全部穴埋めにしたうえで、穴埋めの個数が120個もあることになんで疑問を持たないの！？　あとpythonコードはファイルに書いてよ。後でまだ使うでしょ。そもそも、末尾の`?????????MathML ????????????????`は何！？

どうもLunaちゃんは穴埋め問題の作り方をあまり心得ていないようなので、少しカードの作り方を学習する必要がある。今回はankiのカードづくりのプロであるCherryさんが、#link("https://ko-fi.com/s/7ff7f4205c")[Cherry's 3 Rules of Card Creation (and How to Learn Anything) ]を公開してくれているので、それを参考にする。（驚くべきことに、Cherryさんはすごいクオリティのカードを無償で提供している。もちろんこのガイドも）このガイドによれば、今回の場合ではどうやら、Extraにいろいろ書いて、穴埋め部分は簡潔にするのがよいらしい。思い出してみると、原文をそのまま穴埋めにするのは、自分でカードを作るときには文章を新たに書くのが大変だから、という理由でやっていたことだった。今回はAIにカードを作らせるので、文章を新たに書くのもAIに任せればよい。

というわけで、ガイドを参考にして、まずはカードのフォーマットを決めた。具体的には資料の該当部分をExtraとして付けてもらって、穴埋め自体はAIの書いた文章の穴埋めとする。

#prompt_box()[getting_started.mdをankiの穴埋め問題にして。
  - 一フィールド目に穴埋め問題、二フィールド目(extra)には原文の該当する部分を入れる
  - エスケープ処理はpythonを使って機械的に行うこと
  - 出力ファイルはcsv形式にすること
]

#answer_box()[
  #codly-range(1, end: 3)
  #raw(read("generated/v2/getting_started_cloze.csv"), lang: "csv", block: true)
]

本当に該当部分だけを取り出してしまった。そうじゃない。それじゃあつける意味がないだろう。それに、途中で作成したpythonコードを使わないからと最後に削除してしまった。今後も利用して色々つけ足すことになるのだから、削除しないで残しておくべきだろう。

今度は文脈をリセットせずに、続けてプロンプトを追加してみる。

#prompt_box()[
  該当部分をつけるのは、後でこの穴埋めカードを見た時に復習できるようにつけているから、本当に該当部分を抜き出すのじゃなくて、そこに関連する部分をまとめて抜き出して欲しい。あと、この穴埋め問題作成はルーチンワークになるから、今後も使いそうなファイルやコードはそのまま残しておいて。
]

#answer_box()[
  #codly-range(1, end: 30)
  #raw(read("generated/v3/getting_started_cloze.csv"), lang: "csv", block: true)
]

ぎりぎり実用に耐えるかもしれないくらいの穴埋め問題ができた。ただ、フォーマットがHTMLではなくmarkdownになっているので、Ankiに取り込むときにHTMLに変換する必要がある。また、穴埋めの文章が単体で完結しておらず、前後の穴埋め問題の文章とつながってしまっている。

#prompt_box()[
  だいぶましにはなったけれども、穴埋め問題としてはまだ問題があるね
  - Ankiの穴埋めのフォーマットがmarkdownではなくて、HTMLなので、変換するライブラリを使って変換してください
  - 各ノート（csvの行）が独立していない。（例えば二行目は一行目からつなげて読まないと意味が分からない）この場合は、文章が独立になるように書くか、あるいは問題をまとめて{{c1::}},{{c2::}}...としてください。
]

#answer_box()[
  #codly-range(1, end: 20)
  #raw(read("generated/v4/getting_started_cloze.csv"), lang: "csv", block: true)
]

かなり良くなったが、そもそも穴埋めの仕方が下手ということに気づいた。
例えば
```html
<p>MathML は HTML と同じ {{c1::構文}} を用いて要素と属性のツリーを表します。</p>
```
は問題として自明すぎる。構文以外に何が入るんだ。
```html
<p>MathMLの {{c1::&lt;mfrac&gt;}} 要素は、{{c1::分子（最初の子）}} と {{c1::分母（2 つ目の子）}} を持つ分数を指定します。
```
分数には分子と分母があることは自明すぎる。といった具合に、穴埋めの仕方が結構下手である。

さらに、MDNのフォーマットのせいで起こる問題が二つほどある。
```html
<h2>HTML に \<math> 要素で数式を挿入する</h2>
```
なぜかMDNではhtmlタグのエスケープ方法が二通りあり、\\\<math>のようにバックスラッシュでエスケープしている場合と#"`<math>`"のようにエスケープする場合の二通りがある。後者は上手く処理で来ているが、前者はankiのレンダラーが\\\<math>をhtmlタグとして認識してしまい、\\\<math>の部分が消えてしまう。
```html
<p>LaTeXでは、インライン数式を {{c1::$...$}}、ディスプレイ数式を {{c1::\[...\]}} で区切ります。</p>
```
この穴埋め問題では、ankiのLatexレンダラーが（後半の\\\[...\\\]だけ）本当に起動してしまった。これどうやって回避するんだろう。（まぁ、めったに起こらないケースなのでスルーしてもいいんだけど。）

そして、この穴埋め問題作成のために作られたpythonコードにも問題がある。一般の穴埋めカード作成に使うコードの中に、MDNの独自処理対策が入り込んでしまっている。

あと、欲を言えば、コード例のMathMLレンダリングもしてほしいなぁ。

#prompt_box()[
  - どうやらまだMDNの独自記法があってその部分が上手くいってないみたい。というのも、 htmlタグのエスケープ方法が`<math>`と\<math>の二種類あって、後者がエスケープできていない
  - \[\]とそのまま書くとankiに内蔵されているMathJaxが反応して勝手にれんだりんぐされてしまう
  - このスクリプトは他の穴埋め問題作成にも使うから、MDN独自仕様の対応は別のファイルに分離して欲しい
]
#answer_box()[
  修正しました。

  - `mdn_preprocessor.py` を追加
    - `\<math>` / `\<mrow>` を `&lt;math&gt;` 形式へ変換
    - MDNの `live-sample` 付きコードフェンスを標準Markdownへ変換
    - MDN専用マクロを除去
  - `_generate_cloze_csv.py` は汎用処理とMDN処理を分離
  - `getting_started_cloze.csv` を再生成
    - `\[...\]` は `<code>` 内に入れ、AnkiのMathJaxによる自動描画を防止

  CSVは12行すべてについて、2フィールド構成とHTML変換を検証済みです。
]

とりあえず、MDNの独自処理を分離させることに成功した。latexの自動レンダリングはこの策では回避できなかった。少し自分で調べてみると、#link("https://forums.ankiweb.net/t/how-to-enter-or-backslash-parenthesis-literally/42853")[Ankiのフォーラム]で、#"\&#x200D;"のようにゼロ幅スペースを入れると回避できることがわかった。

#answer_box()[
  修正しました。

  - `\[` / `\]` の前に `&#x200D;` を挿入し、AnkiのMathJax自動描画を抑制
  - MDNの通常のHTMLコード例も、コード表示とMathMLのレンダリング結果を併記
  - MDN固有処理は `mdn_preprocessor.py` に分離
  - 生成処理は `_generate_cloze_csv.py` に保持
  - `getting_started_cloze.csv` を再生成

  12ノートすべてで、コード例とレンダリング結果の対応、MathJax対策、MDN記法の除去を検証済みです。
]

よしよし。次は、ファイルの冒頭にフィールド名やノートタイプ、タグ、セパレータの情報を入れさせて、使っているpythonコードが毎回出力先のファイル名も指定する必要があることになっていたので、それを自動で出力するようにしてもらうことにした。

カードにguidを付ける必要はあるのか......？　微妙だなぁ。

あと、テストコードも保存しておくことにした。
#prompt_box()[
  とてもよくなりましたが、まだ改善点があります。
  - 引数のoutputにデフォルトの値を追加してください。デフォルト値はsourcewithoutextesiontion_cloze.csvとしてください。
  - 出力するcsvの冒頭にankiの取り込み時に使用するファイルヘッダーを追加してください。separatorはComma,htmlはtrue,notetypeは"穴埋め左寄せ",columnsは"テキスト","裏面追記"として、tagsはとりあえず入力したファイルへの相対パスを付けてください。
  - 今後の開発に使用するために、テストコードも保存してください
]
#answer_box()[
  対応しました。

  - `output` を省略すると、入力ファイルの拡張子を除いた名前に `_cloze.csv` を付けて出力
    - 例: `getting_started.md` → `getting_started_cloze.csv`
  - CSV冒頭にAnki用ヘッダーを追加
    - separator: Comma
    - html: true
    - notetype: 穴埋め左寄せ
    - columns: テキスト, 裏面追記
    - tags: 入力ファイルの相対パス
  - テストコードを追加

  追加・更新ファイル:

  - `_generate_cloze_csv.py`
  - `test_generate_cloze_csv.py`
  - `getting_started_cloze.csv`

  テスト3件すべて成功し、CSVヘッダーと出力内容も確認済みです。
]

最後に、一番調整が大変そうな、穴埋めの難易度の調整をしてもらうことにした。

#prompt_box()[
  ノートの表示についてはもう改善点はないから、次は穴埋め問題の難易度調整に移ろう。
  今の問題だと、簡単な問題しかないから、もう少し難しい問題も追加して。
]
#answer_box()[
  高難度の穴埋め問題を7問追加し、合計19問にしました。

  追加内容:

  - `display` 属性と `math-style` の対応
  - LaTeXのdisplay数式との対応
  - `<mn>` / `<mo>` の構造復元
  - `<mfrac>` と `<mrow>` の組み合わせ
  - 分数の入れ子構造3パターン
  - 複数cloze（`c1`〜`c4`）を使った構造問題

  更新ファイル:

  - `_generate_cloze_csv.py`
  - `getting_started_cloze.csv`
  - `test_generate_cloze_csv.py`

  テスト3件すべて成功しています。
]
まだ難易度が低いのでさらに上げてもらう。

#prompt_box()[
  まだ難易度が低いから、難易度が低すぎる問題を削除して、さらに難しい問題を追加して
]
#answer_box()[
  難易度を調整しました。

  - 単純な要素名の暗記問題とまとめ問題を削除
  - MathMLコードの完成問題を5問追加
  - 分数の入れ子構造、`<mrow>` の配置、`<mfrac>` の子要素数を問う問題を追加
  - 複数clozeを使った構造問題を中心に構成
  - 全13問に整理

  更新ファイル:

  - `_generate_cloze_csv.py`
  - `getting_started_cloze.csv`
  - `test_generate_cloze_csv.py`

  生成処理とテスト3件はすべて成功しています。
]

まあとりあえずはいいかなというくらいの出来になったので、これをskillにまとめさせて、今後はこのskillを使って穴埋め問題を作らせることにした。

#prompt_box()[
  /create-skill 今回作成したカードと同じようなカードを別の資料から作れるようにskillとしてまとめてください。
]
#answer_box()[
  個人用スキルとして作成しました。

  `~/.agents/skills/anki-cloze-author/SKILL.md`

  今回のワークフローを以下の手順として整理しています。

  - Markdown資料の構造解析
  - MDNなど資料固有の前処理の分離
  - 独立した穴埋め問題の設計
  - 構造復元・コード完成・妥当性判断による難易度調整
  - MarkdownからAnki用HTMLへの変換
  - MathJax対策
  - Anki CSVヘッダーと相対パスタグの生成
  - 回帰テストと出力検証

  次回は例えば次のように呼び出せます。

  ```text
  このMarkdown資料から、anki-cloze-authorを使って難しめの穴埋めカードを作ってください。
  ```

  フロントマターと内容を確認済みです。
]

コードを含めていなかったのでその部分を追加させる。
#prompt_box()[
  今回使ったコードを今後改変して使えるようにコードも保存して置いて#footnote("この誤字はプロンプトを書いたタイミングでの誤字です")
]
#answer_box()[
  今回使用したコードをスキル内に保存しました。

  保存先:

  `~/.agents/skills/anki-cloze-author/scripts/`

  - `generate_cloze_csv.py`
  - `mdn_preprocessor.py`
  - `test_generate_cloze_csv.py`

  スキル本文からも参照できるよう更新済みです。テストは実際の `getting_started.md` を使って3件すべて成功しています。
]
#raw(read("generated/anki-cloze-author/v1/SKILL.md"), lang: "markdown", block: true)
う～ん、悪くはないが、MDNやMathMLに特化しすぎている。
#codly-range(41, end: 53)
#raw(read("generated/anki-cloze-author/v1/SKILL.md"), lang: "markdown", block: true)
#codly-range(67, end: 73)
#raw(read("generated/anki-cloze-author/v1/SKILL.md"), lang: "markdown", block: true)

とりあえず、MDNのMathMLのページから作るぶんには使えそうなので、使ってみてから考えることにする。

保存先は、リポジトリ固有のところの方がいいな。
#prompt_box()[
  このワークスペースは穴埋め問題作成のためのワークスペースだから、保存先はこのワークスペース内にしてほしいな
]

#answer_box()[
  保存先をワークスペース内へ移しました。

  - `SKILL.md`
  - `generate_cloze_csv.py`
  - `mdn_preprocessor.py`
  - `test_generate_cloze_csv.py`

  個人フォルダー側の重複ファイルは削除しました。ワークスペース内の同梱テスト3件も成功しています。
]

じゃあ、セッションを切り替えて、別の資料から穴埋め問題を作ってみよう。

#link("https://github.com/mdn/translated-content/blob/4d60048518bfbe8ee8ffa0c89a2f141983f88c1a/files/ja/web/mathml/tutorials/for_beginners/text_containers/index.md")[MDN-MathML テキストコンテナ]を題材にして、穴埋め問題を作ってみる。
#prompt_box()[
  /anki-cloze-author
]
#answer_box()[
  `index.md` 用の Anki cloze 生成を追加しました。

  - 生成器
  - 回帰テスト
  - 生成済み CSV

  12 枚のカードを生成し、複数 cloze・MDN マクロ除去・コードの rendered-result 保存を確認済みです。テスト結果: `Ran 3 tests ... OK`。
]
難易度が最初の簡単な状態に戻ったうえに、コードに説明がなく、さらにテストにページ固有の処理が入っていたことが分かった。

また、何故かスクリプトの場所が書いてあるのにも関わらず、そのスクリプトを見つけられず最終的にはスキルの作成元となったほうのskill外のスクリプトを使ってしまった。

というわけで、セッションを戻して直させる。

#prompt_box()[
  別セッションでこのスキルを実行させてみたところ、以下の問題点が見つかりましたので修正してください。
  - 難易度が最初の簡単すぎる状態に戻ってしまった。
  - コードに説明がなくどのように入力すればいいのか、どう動いているのかが実際に読み取らないとわからない
  - skill内のスクリプトを見つけられず、作成元のmathmlフォルダ内のスクリプトを使ってしまった
]
（テストのページ固有処理は自分で消した方が早いので自分で消した）
#answer_box()[
  別セッションでの問題点を修正しました。

  - 難易度低下対策
    - スキルに「難易度ゲート」を追加
    - 構造復元・コード完成・診断問題を最低条件として明記
    - 古い定義暗記中心のカードセットへ戻さないよう指示
    - テストでも複数clozeを検証

  - コードの説明不足対策
    - 生成器、MDN前処理、テストにdocstringとコメントを追加
    - 入力方法、`CARDS` の形式、処理手順を説明
    - scripts/README.md を追加

  - スクリプト探索先の問題
    - 正本を明示:
      `generate_cloze_csv.py`
    - `_generate_cloze_csv.py` は旧・資料専用スナップショットとして明記
    - スキルから正本のパスを明示

  ワークスペース内の正本スクリプトを直接実行し、テスト3件すべて成功しています。
]

なんだかAIどうしを戦わせてるみたいになってきた。僕がレフェリー。

もう一回セッションを切り替えて、別の資料から穴埋め問題を作ってみる。

毎回同じことを言うのも面倒なのでプロンプトファイルを作って、そこから呼び出すようにした。
#prompt_box()[
  ```
  ---
  name: create-anki-cloze
  description: Create Anki cloze deletion cards from a Markdown file
  ---

  <!-- Tip: Use /create-prompt in chat to generate content with agent assistance -->

  /anki-cloze-author index.mdからankiの穴埋め問題を作って
  ```
]
#answer_box()[
  `index.md` からAnki用の穴埋めカードを作成しました。

  - `index_cloze.csv`: 9枚
  - `generate_cloze_csv.py`: 再生成用スクリプト
  - 8枚が複数cloze、コード例とMDNマクロも適切に処理済み
  - CSV形式、HTML、Ankiヘッダーを検証済み
  - 診断エラーなし
]

驚くべきことに、難易度は一切変わらず、さらに問題文が意味不明なものがいくつかでき、さらにクオリティーが下がった。しかも相変わらずスクリプトの実行に何回も失敗していて、あきらかにそちらに気を取られている。

というか、検証用のテストコードがあるのに、明らかにそのコードを無視している。お前らあほなんか？？

大幅に方針を転換して、skillの中にあるコードを映してから少し書き換えて使うのではなく、入力用のcsvファイルを作らせて、そのパスを
skillの中にあるコードに渡して実行したら、出力ファイルが出来て、さらに自動的にskillの中にあるテストコードを使って検証する、という形に変える。これなら、skillの中にあるコードをいじる必要がなくなるので、skillの中のコードに気を取られて穴埋め問題がよわよわになることが防げるかもしれない。

スキルは変えれたが、中身を見ると既存の文章をすべて残したうえで加筆していて、矛盾する部分や無意味な部分が大量に存在した。

もう諦めてガイド自体を直接与えてみたりもしたが、ほんのちょっとだけ改善した程度で、やはり穴埋め問題の質は低いままだった。

というわけで本日はここまで。今後のAIの進化に期待することにする。
