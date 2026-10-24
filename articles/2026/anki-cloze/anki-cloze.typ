#import "/template/template.typ": *
#show: show_blog_with_typst

#let prompt_box(prompt) = context {
  if (target() == "html") {
    html.elem("div", attrs: (style: "padding: 1em; border: 1px solid #111;"))[
      プロンプト:

      #prompt
    ]
  } else {
    block(breakable: true, fill: white.darken(2.5%), inset: 1em)[
      プロンプト:

      #prompt
    ]
  }
}
#let answer_box(answer) = context {
  if (target() == "html") {
    html.div(style: "background-color: #f0f0f0; padding: 1em; border: 1px solid #ccc;")[
      #block(breakable: true, fill: white.darken(2.5%), inset: 1em)[
        回答:

        #answer
      ]
    ]
  } else {
    block(breakable: true, fill: white.darken(2.5%), inset: 1em)[
      回答:

      #answer
    ]
  }
}

= （私の）理想のAnkiの穴埋め問題を作らせる
== Anki?
私は普段の学習でAnkiを使っている。Ankiはフラッシュカード#footnote("実際にはHTMLなので、その気になれば色々なことができる")を使った学習ツールで、ただ単に暗記するだけでなく、自由記述や計算問題も作れる。また、Ankiにはいくつかのノートタイプ（問題の種類）があるが、私は主に「Cloze」というノートタイプを使っている。Clozeは文章の一部を隠して穴埋め問題にすることができるノートタイプで、私は読んだ文章をそのままコピーして、その文章を穴埋め問題にしてAnkiに取り込むことが多い。文章をそのままコピーするので自分で文章を書く時間を節約でき、また自分が間違ったまとめ方をしてしまうこともない。#footnote("なんなら何度も解くうちに原文の間違いに気づくこともある。")

最近、AIのLunaちゃんにコードに書かせてみたところ、自分より早く、正確に、そして大量に書けることが分かった。だったら、Ankiの穴埋め問題もAIに作らせてみようと思った。Ankiの穴埋め問題は、文章をそのままコピーして穴埋めにするだけなので、そんなに難しくないはず！（フラグ）
== 使ったもの
- 使用したAI:GPT-5.6-Luna(Github Copilot Chat)

AIの使い方はだいぶ初心者なので、Ankiのカード作成にこのモデル選択があっているかはさっぱり分からない。調べようにもニッチすぎて何も参考に出来そうにないし......

== まずはテスト
とりあえず、穴埋め問題を作らせるテストをしてみる。
作らせる題材にするのは、#link("https://github.com/mdn/translated-content/blob/4d60048518bfbe8ee8ffa0c89a2f141983f88c1a/files/ja/web/mathml/tutorials/for_beginners/getting_started/index.md")[MDN-MathML を始めよう] としてみる。（ちょうど自分が勉強していた。）まずは簡単に指示してみてどうなるかを見てみる。

#prompt_box("getting_started.mdをankiの穴埋め問題にして")

で、できたのがこれ。
/v1/getting_started_cloze.md
#answer_box()[
  ````
  # MathML を始めよう: Anki Cloze カード

  Anki の「Cloze」ノートタイプで使用してください。各コードブロック内の 1 行が 1 ノートです。

  ## 基本

  ```text
  MathML の数式を HTML 文書に挿入する要素は {{c1::<math>}} である。
  ```

  ```text
  MathML は HTML と同じく、{{c1::要素と属性のツリー}}で構文を表す。
  ```

  ```text
  分数を表す MathML 要素は {{c1::<mfrac>}} である。
  ```
  ......
  ````
]
どうやって取り込めと？　あと、せっかく資料を渡したのに一から書き直さないでくれ。それだったら資料を渡さずに直接「mathmlの穴埋め問題を作れ」と言うよ！　後簡単すぎない？

まぁ、なにはともあれ、穴埋め問題のフォーマットは知っていることは確認できたが、どうもあまりAnkiの穴埋め問題の作り方の知識と穴埋め問題作成自体のセンスがなさそう。なので、公式ドキュメントの#link("https://github.com/ankitects/anki-manual/blob/00c7a9b31c0cf967ec44be74b6a56e188db5c311/src/importing/text-files.md")[importのページ]を読ませてまずは知識を補充して再挑戦。（プロンプトは同じ）
//v1/getting_started_cloze.txt
#answer_box()[
  ````
  #notetype:Cloze
  #html:true
  #tags:mathml getting-started
  MathML は HTML と同じ構文を用いて、{{c1::要素と属性のツリー}}を表す。<br>数式全体は {{c2::&lt;math&gt;}} 要素で表す。
  HTML ページ内に MathML 数式を挿入するには、{{c1::&lt;math&gt;}} 要素を配置する。
  {{c1::&lt;mfrac&gt;}} 要素は、最初の子を {{c2::分子}}、2 つ目の子を {{c3::分母}} とする分数を指定する。
  ......
  ````
]
今度はtxtファイルで正しい形式で出力してくれたので、Ankiに取り込める。が、やはり文章を一から書き直してしまっていて、資料を与えた意味があまりない。あと、txtファイルではなくcsvファイルで出力してくれた方がAnkiに取り込みやすいし、後から編集もしやすい。（なぜか公式ドキュメントではtxtになっているが）というわけで、プロンプトを変えて再度挑戦。

#prompt_box(
  "getting_started.mdをankiの穴埋め問題にして。
- 原文をそのまま穴埋めにすること
- エスケープ処理はpythonを使って機械的に行うこと
- 出力ファイルはcsv形式にすること",
)
//v1/getting_started_cloze.csv
#answer_box()[
  （筆者による抜粋）変換単位は、原文全体を 1 件の Cloze ノートにする形にします。本文の説明文・コード例・見出しは残し、MathML の主要要素名と display / CSS プロパティ名を原文の該当箇所だけ Cloze 化します。次に Python の re と csv.writer で CSV を生成し、読み戻して列数・Cloze 数・改行保持を検査します。
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
  ```
  （省略）

  122 個の Cloze マーカーが生成され、CSV は 2 行・各 2 列として読み戻せています。

  ````
  Text,Extra
  "---
  title: MathML を始めよう
  short-title: 始めよう
  slug: Web/MathML/Tutorials/For_beginners/Getting_started
  l10n:
    sourceCommit: 6b01bafc68dffb3a50f70882d2ba24cd6f9d886f
  ---

  {{NextMenu(""Web/MathML/Tutorials/For_beginners/Text_containers"", ""Web/MathML/Tutorials/For_beginners"")}}

  この記事では、単純な HTML 文書を使い、そこに MathML 数式を追加する方法を、いくつかの要素を紹介しながら見ていきます。
  ````
  （中略）
  ````
    <ol>
    <li>
      「2 分の 1」足す「3 分の 2」:
      <!-- math 要素の子要素を mrow 要素でグループ化するのは正しいですが、不必要です。 -->
      {{c55::<math>}}
        {{c56::<mfrac>}}
          {{c57::<mn>}}1{{c58::</mn>}}
          {{c59::<mn>}}2{{c60::</mn>}}
        {{c61::</mfrac>}}
        {{c62::<mo>}}+{{c63::</mo>}}
        {{c64::<mfrac>}}
          {{c65::<mn>}}2{{c66::</mn>}}
          {{c67::<mn>}}3{{c68::</mn>}}
        {{c69::</mfrac>}}
      {{c70::</math>}}
    </li>
    <li>
      「1 足す 2 足す 3」が「4 足す 5」の上にある:
      {{c71::<math>}}
        {{c72::<mfrac>}}
          {{c73::<mrow>}}
            {{c74::<mn>}}1{{c75::</mn>}}
            {{c76::<mo>}}+{{c77::</mo>}}
            {{c78::<mn>}}2{{c79::</mn>}}
            {{c80::<mo>}}+{{c81::</mo>}}
            {{c82::<mn>}}3{{c83::</mn>}}
          {{c84::</mrow>}}
          {{c85::<mrow>}}
            {{c86::<mn>}}4{{c87::</mn>}}
            {{c88::<mo>}}+{{c89::</mo>}}
            {{c90::<mn>}}5{{c91::</mn>}}
          {{c92::</mrow>}}
        {{c93::</mfrac>}}
      {{c94::</math>}}
    </li>
    <li>
      「4 分の 1」が「2 足す 3」の上にある:
      {{c95::<math>}}
        {{c96::<mfrac>}}
          {{c97::<mfrac>}}
            {{c98::<mn>}}1{{c99::</mn>}}
            {{c100::<mn>}}4{{c101::</mn>}}
          {{c102::</mfrac>}}
          {{c103::<mrow>}}
            {{c104::<mn>}}2{{c105::</mn>}}
            {{c106::<mo>}}+{{c107::</mo>}}
            {{c108::<mn>}}3{{c109::</mn>}}
          {{c110::</mrow>}}
        {{c111::</mfrac>}}
      {{c112::</math>}}
    </li>
  </ol>
  ````
  （中略）
  ````
    - {{cssxref(""{{c121::math-style}}"")}} プロパティ
  - {{cssxref(""{{c122::math-depth}}"")}} プロパティ

  {{NextMenu(""Web/MathML/Tutorials/For_beginners/Text_containers"", ""Web/MathML/Tutorials/For_beginners"")}}",?????????MathML ????????????????
  ````
]


どうしてそうなった！？　原文をそのままってそういう意味じゃねぇよ！！！　あと、同じ単語全部穴埋めにしたうえで、穴埋めの個数が120個もあることになんで疑問を持たないの！？　あとpythonコードはファイルに書いてよ。後でまだ使うでしょ。そもそも、末尾の`?????????MathML ????????????????`は何！？

どうもLunaちゃんは穴埋め問題の作り方をあまり心得ていないようなので、少しカードの作り方を学習する必要がある。今回はankiのカードづくりのプロであるCherryさんが、#link("https://ko-fi.com/s/7ff7f4205c")[Cherry's 3 Rules of Card Creation (and How to Learn Anything) ]を公開してくれているので、それを参考にする。（驚くべきことに、Cherryさんはすごいクオリティのカードを無償で提供している。もちろんこのガイドも）このガイドによれば、今回の場合ではどうやら、Extraにいろいろ書いて、穴埋め部分は簡潔にするのがよいらしい。思い出してみると、原文をそのまま穴埋めにするのは、自分でカードを作るときには文章を新たに書くのが大変だから、という理由でやっていたことだった。今回はAIにカードを作らせるので、文章を新たに書くのもAIに任せればよい。

というわけで、ガイドを参考にして、まずはカードのフォーマットを決めた。具体的には資料の該当部分をExtraとして付けてもらって、穴埋め自体はAIの書いた文章の穴埋めとする。

#prompt_box()[getting_started.mdをankiの穴埋め問題にして。
  - 一フィールド目に穴埋め問題、二フィールド目(extra)には原文の該当する部分を入れる
  - エスケープ処理はpythonを使って機械的に行うこと
  - 出力ファイルはcsv形式にすること
]
//v2/getting_started_cloze.csv
#answer_box()[
  ````csv
  MathML は HTML と同じ {{c1::構文}} を用いて要素と属性のツリーを表します。,MathML は HTML と同じ構文を用いて要素と属性のツリーを表します。
  具体的な数式は {{c1::<math>}} 要素で表されます。,具体的な数式は `<math>` という要素で表され、 HTML ページの中に配置することができます。
  <mfrac> は {{c1::分子（最初の子）}} と {{c1::分母（2 つ目の子）}} を持つ分数を指定します。,`<mfrac>` 要素は分子（最初の子）と分母（2 つ目の子）を持つ分数を指定します。
  ````
]

本当に該当部分だけを取り出してしまった。そうじゃない。それじゃあ資料をわざわざつける意味がないだろう。（出典確認に使うにしても、この部分だけじゃどこから出てきたか探すのが大変）それに、途中で作成したpythonコードを使わないからと最後に削除してしまった。どのみち今後も利用して色々つけ足すことになるのだから、削除しないで残しておくべきだろう。

ここまではあまりに出来がひどかったので、毎回セッションをリセットして最初からやり直していたが、今度は文脈をリセットせずに、同じセッションに続けてプロンプトを追加してみる。

#prompt_box()[
  該当部分をつけるのは、後でこの穴埋めカードを見た時に復習できるようにつけているから、本当に該当部分を抜き出すのじゃなくて、そこに関連する部分をまとめて抜き出して欲しい。あと、この穴埋め問題作成はルーチンワークになるから、今後も使いそうなファイルやコードはそのまま残しておいて。
]
//v3/getting_started_cloze.csv
#answer_box()[
  ````
   MathML は HTML と同じ {{c1::構文}} を用いて要素と属性のツリーを表します。,"この記事では、単純な HTML 文書を使い、そこに MathML 数式を追加する方法を、いくつかの要素を紹介しながら見ていきます。

  ## HTML に \<math> 要素で数式を挿入する

  MathML は HTML と同じ構文を用いて要素と属性のツリーを表します。具体的な数式は `<math>` という要素で表され、 HTML ページの中に配置することができます。以下の文書では、段落の中にあります。

  ```html live-sample___inserting_formulas_in_html
  <p>
    分数
    <math>
      <mfrac>
        <mn>1</mn>
        <mn>3</mn>
      </mfrac>
    </math>
    は十進数では表せません。
  </p>
  ```

  `<mfrac>` 要素は分子（最初の子）と分母（2 つ目の子）を持つ分数を指定します。ブラウザーではこのように表示されます。"
  具体的な数式は {{c1::<math>}} 要素で表されます。,"MathML は HTML と同じ構文を用いて要素と属性のツリーを表します。具体的な数式は `<math>` という要素で表され、 HTML ページの中に配置することができます。以下の文書では、段落の中にあります。

  ```html live-sample___inserting_formulas_in_html
  <p>
    分数
    <math>
      <mfrac>
        <mn>1</mn>
        <mn>3</mn>
      </mfrac>
    </math>
    は十進数では表せません。
  </p>
  ```

  `<mfrac>` 要素は分子（最初の子）と分母（2 つ目の子）を持つ分数を指定します。ブラウザーではこのように表示されます。"
  ````
]

ぎりぎり実用に耐えるかもしれないくらいの穴埋め問題ができた。ただ、フォーマットがHTMLではなくmarkdownになっているので、Ankiに取り込むときにHTMLに変換する必要がある。また、穴埋めの文章が単体で完結しておらず、前後の穴埋め問題の文章とつながってしまっている。

#prompt_box()[
  だいぶましにはなったけれども、穴埋め問題としてはまだ問題があるね
  - Ankiの穴埋めのフォーマットがmarkdownではなくて、HTMLなので、変換するライブラリを使って変換してください
  - 各ノート（csvの行）が独立していない。（例えば二行目は一行目からつなげて読まないと意味が分からない）この場合は、文章が独立になるように書くか、あるいは問題をまとめて{{c1::}},{{c2::}}...としてください。
]
//v4/getting_started_cloze.csv
#answer_box()[
  ````
  <p>MathML は HTML と同じ {{c1::構文}} を用いて要素と属性のツリーを表します。</p>,"<p>この記事では、単純な HTML 文書を使い、そこに MathML 数式を追加する方法を、いくつかの要素を紹介しながら見ていきます。</p>
  <h2>HTML に \<math> 要素で数式を挿入する</h2>
  <p>MathML は HTML と同じ構文を用いて要素と属性のツリーを表します。具体的な数式は <code>&lt;math&gt;</code> という要素で表され、 HTML ページの中に配置することができます。以下の文書では、段落の中にあります。</p>
  <pre><code class=""language-html"">&lt;p&gt;
    分数
    &lt;math&gt;
      &lt;mfrac&gt;
        &lt;mn&gt;1&lt;/mn&gt;
        &lt;mn&gt;3&lt;/mn&gt;
      &lt;/mfrac&gt;
    &lt;/math&gt;
    は十進数では表せません。
  &lt;/p&gt;
  </code></pre>
  <p><code>&lt;mfrac&gt;</code> 要素は分子（最初の子）と分母（2 つ目の子）を持つ分数を指定します。ブラウザーではこのように表示されます。</p>"
  <p>HTMLページに具体的な数式を配置するための要素は {{c1::&lt;math&gt;}} です。</p>,"<p>MathML は HTML と同じ構文を用いて要素と属性のツリーを表します。具体的な数式は <code>&lt;math&gt;</code> という要素で表され、 HTML ページの中に配置することができます。以下の文書では、段落の中にあります。</p>
  <pre><code class=""language-html"">&lt;p&gt;
    分数
    &lt;math&gt;
      &lt;mfrac&gt;
        &lt;mn&gt;1&lt;/mn&gt;
        &lt;mn&gt;3&lt;/mn&gt;
      &lt;/mfrac&gt;
    &lt;/math&gt;
    は十進数では表せません。
  &lt;/p&gt;
  </code></pre>
  <p><code>&lt;mfrac&gt;</code> 要素は分子（最初の子）と分母（2 つ目の子）を持つ分数を指定します。ブラウザーではこのように表示されます。</p>"
  ````
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
  - どうやらまだMDNの独自記法があってその部分が上手くいってないみたい。というのも、 htmlタグのエスケープ方法が`<math>`と\\<math>の二種類あって、後者がエスケープできていない
  - \\\[\\\]とそのまま書くとankiに内蔵されているMathJaxが反応して勝手にれんだりんぐされてしまう
  - このスクリプトは他の穴埋め問題作成にも使うから、MDN独自仕様の対応は別のファイルに分離して欲しい
]
//v5/getting_started_cloze.csv
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
//v6/getting_started_cloze.csv
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
//v7/getting_started_cloze.csv
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
//v8/getting_started_cloze.csv
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
//v9/getting_started_cloze.csv
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
````
---
name: anki-cloze-author
description: 'Create difficult, self-contained Anki cloze notes from Markdown or MDN-style documents. Use when converting technical documentation into HTML-enabled cloze CSV files, designing multi-cloze structure questions, handling Markdown/MDN syntax, preserving code examples, or adding regression tests.'
argument-hint: 'Source Markdown file and desired learning scope'
user-invocable: true
---

# Anki Cloze Author

Create Anki cloze notes from technical documents while keeping each note independently reviewable and suitable for Anki's HTML fields.

## When To Use

Use this skill when the user asks to:

- turn a Markdown, MDN, or technical document into Anki cloze cards;
- produce a CSV for Anki import with HTML fields;
- make cards harder by testing structure, reconstruction, comparison, or diagnosis;
- preserve code examples and rendered HTML/MathML in the extra field;
- create a repeatable generator and tests for future source documents.

## Workflow

The reusable implementation from the first MathML conversion is bundled in:

- [generator](./scripts/generate_cloze_csv.py)
- [MDN preprocessor](./scripts/mdn_preprocessor.py)
- [regression test template](./scripts/test_generate_cloze_csv.py)

Copy or adapt these files for a new source. Replace the source-specific `CARDS`
definitions and markers; keep the HTML conversion, CSV headers, MathJax guard,
and validation code unless the target note type requires a deliberate change.

### 1. Inspect The Source

1. Read the source and identify its conceptual sections, code examples, exercises, and summaries.
2. Check whether the document has source-specific syntax such as MDN macros, escaped angle brackets, special code-fence labels, or live-sample directives.
3. Inspect existing project conventions, dependencies, generators, and tests before editing.
4. State a local hypothesis about the source structure and choose a cheap validation check before making the first edit.
### 2. Separate Source-Specific Preprocessing

Keep document-specific normalization separate from the generic card generator.

For MDN-style input, use a separate preprocessor module to:

- convert `\\<tag>` and `\\>` notation into HTML-safe text;
- remove navigation and embedding macros such as `NextMenu` and `EmbedLiveSample`;
- normalize `live-sample` code fences;
- preserve the code and add a rendered-result block for HTML/MathML examples;
- convert ordinary HTML code fences to the same code-plus-rendered-result representation when rendering is useful.

Do not put MDN rules into the generic Markdown-to-HTML function. Add a new preprocessor for another document dialect.
...
````
う～ん、悪くはないが、MDNやMathMLに特化しすぎている。


とりあえず、MDNのMathMLのページから作るぶんには使えそうなので、使ってみてから考えることにする。

保存先は、リポジトリ固有のところの方がいいな。
#prompt_box()[
  このワークスペースは穴埋め問題作成のためのワークスペースだから、保存先はこのワークスペース内にしてほしいな
]
//anki-cloze-author/v1
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
//text_containers/v1
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
//anki-cloze-author/v2
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
//text_containers/v2
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
//anki-cloze-author/v3
#answer_box()[
  ````


  スキルの構成を大幅に変更しました。

  ## 新しい使い方

  新しい資料ごとに作成するのは、カード仕様CSVだけです。

  各行:

  ```text
  穴埋め問題,extra開始文字列,extra終了文字列
  ```

  実行:

  ```powershell
  python .agents\skills\anki-cloze-author\scripts\generate_cloze_csv.py `
    カード仕様.csv 原文.md [出力.csv]
  ```

  生成器が自動的に以下を行います。

  1. カード仕様CSVを読み込む
  2. 原文からextraを抽出する
  3. HTMLへ変換する
  4. Anki CSVを生成する
  5. `test_generate_cloze_csv.py` を自動実行する
  6. 検証に成功した場合だけ `validation: passed` を表示する

  ## 更新ファイル

  - `SKILL.md`
  - `README.md`
  - `generate_cloze_csv.py`
  - `test_generate_cloze_csv.py`
  - `getting_started_cards.csv`

  `_generate_cloze_csv.py` は旧資料専用として残していますが、新しい資料では使用しません。

  新方式で13問を生成し、バリデータも成功しています。

  変更を行いました。
  ````
]

スキルは変えれたが、SKILL.md中身を見ると既存の文章をすべて残したうえで加筆していて、矛盾する部分や無意味な部分が大量に存在していて絶望した。

もう諦めてCherryさんのガイド自体を直接与えてみたりもしたが、ほんのちょっとだけ改善した程度で、やはり穴埋め問題の質は低いままだった。
//anki-cloze-author/v4

というわけで（？）本日はここまで。今後のAIの進化に期待することにする。
