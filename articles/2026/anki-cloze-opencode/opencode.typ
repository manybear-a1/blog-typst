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


今回はOpenRouterではなく#link("https://opencode.ai/docs/ja/ide/")[OpenCode]を使ってみる。

とりあえずちょっと使ってみる
#prompt_box()[
  `@decks/regex/regex-ja.html` Spilit this file into sections
]

#image("image/question.png")

うぉぉ！質問してきた！すげぇ！
#image("image/answer.png")
とりあえず答える。
#answer_box()[
  ```
  Done. I split decks/regex/regex-ja.html into one HTML fragment per top-level <section>, preserving the markup and CRLF line endings exactly.
  Files created in decks/regex/:
  File	Section
  index.html	<h1> title + 概要 preamble (content of the root section before its first child)
  introduction.html	introduction
  simple-patterns.html	simple-patterns (+ matching-characters, repeating-things)
  using-regular-expressions.html	using-regular-expressions (+ 5 subsections)
  more-pattern-power.html	more-pattern-power (+ 4 subsections)
  modifying-strings.html	modifying-strings (+ 2 subsections)
  common-problems.html	common-problems (+ 4 subsections)
  feedback.html	feedback
  Notes:
  Nested <h3> subsections stay inside their parent file (top-level split only, as requested).
  Each file is a standalone <section>…</section> fragment; index.html holds the preamble since the original's <h1> and overview <aside> sit outside any child section.
  I verified that re-joining the root open tag + index.html + the 7 files + root close tag reproduces the original file byte-for-byte, and each file has balanced <section>/</section> tags.
  The original regex-ja.html is untouched. Say the word if you'd like it archived/deleted, or the files moved into a subfolder.
  ```
]
さっき使ったモデルはBig Pickleというモデルだ。しかし今回使いたいのはそのモデルではなく、最近Free Planで使えるようになったDeep Seek 4.1 Flash FreeとGLM5.3 Flashだ。
#prompt_box()[
  ```
  次のルールに従って@decks/regex/introduction.html から穴埋め問題を作成してください。

  - 問題セットはCSV形式で出力してください。
  - 穴埋め箇所は{{c1::答え::ヒント}}、{{c2::答え::ヒント}}のように番号を付けてください。この際、各{{cN::}}から問題が一つ生成されます。
  - 問題は以下の二種類をバランスよく出してください。

    - 普通の穴埋め問題
    - 記述式の穴埋め問題
  ```
  - 難易度は単に単語を聞くような簡単な問題ではなく、自由記述で穴埋めする問題を中心に設定してください。同じような答えになる穴埋め箇所を一つの問題セットに二か所以上作ってはなりません。
]
#answer_box()[
  decks/regex/introduction.html から穴埋め問題を10問作成し、CSV に保存しました。
  ファイル: decks/regex/introduction.csv
  ```
  "正規表現は、Python に埋め込まれた {{c1::小さく高度に特化したプログラミング言語::位置づけ}} であり、`re` モジュールから利用できます。"
  "正規表現を使うと、{{c1::マッチさせたい文字列に適合するような文字列の集合::指定できるもの}} を指定できます。"
  "正規表現では、「この文字列は指定したパターンにマッチするか」のほかに、{{c1::このパターンが文字列のどの部分にマッチするか::もう一つの問い}} を問い合わせることができます。"
  "正規表現を使えば、文字列を変更したり、いろいろな方法で {{c1::別々の部分に分割する::もう一つの操作}} こともできます。"
  "正規表現パターンは一連のバイトコードにコンパイルされ、{{c1::C で書かれたマッチングエンジン::実行するプログラム}} によって実行されます。"
  "正規表現のより進んだ利用法では、{{c1::エンジンが与えられた正規表現をどう実行するか::注意する対象}} に注意し、高速に実行できるバイトコードを生成するように正規表現を書きます。"
  "このドキュメントが正規表現の最適化を扱わないのは、{{c1::マッチングエンジンの内部に対する十分な理解が必要だから::扱わない理由}} です。"
  "正規表現言語は相対的に小さく制限されており、{{c1::あらゆる文字列処理作業を正規表現で行えるわけではない::言語の限界}}。"
  "正規表現で表現すると非常に複雑になる作業では、{{c1::Python コードを書く方がよい::代替手段}} とされています。"
  "複雑な処理を Python コードで書くと、念入りに作られた正規表現より遅くなるものの、{{c1::より読み易い::Pythonコードの利点}} という利点があります。"
  ```
  内容の方針:
  - 普通の穴埋め（短い語句・用語）と記述式の穴埋め（理由・関係・定義を文章で答える）を混在させ、後者を多めにしました。
  - 単語1語だけを問う問題は避け、技術的な用語でも文脈の中で答える形にしています。
  - 10問すべて答えが異なり、同じ答え・類似した答えの穴埋めはありません。
  - 各行は1フィールドの「カード仕様CSV」形式です（decks/mathml/\*/index.csv と同じ形式）。Anki 取り込み用のヘッダー付きCSV（\#separator など）が必要であれば、このCSVから生成できます。
]
かなり日本語の文章が上手くなっている気はする。しかしカードにはまだまだ改善の余地あり。

#prompt_box()[
  \@decks/regex/introduction_revised.csv に今回のカードを調整したバージョンを用意しました。このデッキのカードと以前に作った \@decks/regex/introduction.csv を比較して、このカードを作成するのに不足していた情報をプロンプトに書き足してください
]
#answer_box()[
  ```
    Comparing the two versions, the revised set is not just a wording tweak — it changes the card design. The main differences:
  観点	introduction.csv	introduction_revised.csv
  ノート/カード数	10ノート / 10カード	5ノート / 6カード
  cN の使い方	各行に1個の c1	1ノート内で c1 を複数、c2 も使用
  文のまとまり	1文1カード	関連する隣接文を1ノートに統合
  並列項目	片方だけ空欄	両方を空欄（同じ cN）
  重複ルール	全カード間で類似答案を回避	同一 cN 内の類似は許可
  表現	原文に近い	「のほかに」等を排除し自然な日本語に改写
  ヒント	全問に付与	一部省略
  取捨	全事実をカード化	「文字列の集合」カードを削除
  不足していた情報
  1. cN の意味: 同じ cN は「同じ論点をまとめた1枚のカード」であり、複数の空欄を持てる。異なる cN だけが別カードになる。
  2. ノートの粒度: 1文1カードにせず、同じ話題の隣接文・因果・対比を1ノートにまとめる。
  3. 並列項目の扱い: 列挙・対になる項目は片方だけ空欄にせず、同じ cN で両方を空欄にする。
  4. 空欄にする範囲: 全事実を空欄にせず、中心概念だけを空欄にして説明の流れは地の文で残す。
  5. 重複禁止の単位: 「似た答えを2か所以上作らない」はカード間のルール。同一カード内では関連する類似答案をまとめてよい。
  6. 自己完結性: 「のほかに」「このドキュメントでは」など文脈依存の表現を避け、カード単体で意味が通るようにする。
  7. 文体: 直訳調を避け、問題文として自然な日本語に整える。
  8. ヒント: 必須ではなく、自明なら省略してよい。
  9. 取捨選択: 原文の全事実をカード化せず、学習上重要な概念を優先する。
  以下を decks/regex/introduction.prompt.md に保存しました。
  # Wrotedecks\regex\introduction.prompt.md
  # 穴埋め問題作成プロンプト（regex/introduction）

  次のルールに従って `decks/regex/introduction.html` から穴埋め問題を作成してください。

  ## 出力形式

  - 問題セットは CSV 形式で出力してください。
  - 1行を1ノートとし、各ノートは1つの CSV フィールドとして出力してください。カンマ・改行・ダブルクォートを含む場合は RFC 4180 に従って引用してください。
  - 穴埋め箇所は `{{c1::答え::ヒント}}`、`{{c2::答え::ヒント}}` のように番号を付けてください。
  - 各 cN から1枚のカードが生成されます。同じ cN を複数の空欄で使うと、それらは同じカードの複数の空欄として同時に復習されます。
  - 1ノートに複数の文を含めてかまいません。1文1カードに分割しないでください。

  ## カードのまとまり

  - 1つの cN は、1つの「理解してほしい論点」に対応させてください。その論点を構成する複数の事実・空欄は、同じ cN にまとめてください。
  - 同じ話題の隣接する文、因果関係・対比・列挙の関係にある文は、1つのノートにまとめてください。
  - 並列・列挙・対になる項目（例: 2種類の問い合わせ、2種類の文字列操作）は、同じ cN でまとめて1枚のカードにしてください。
  - 同じノート内でも、独立して復習する価値がある別の論点は、別の cN に分けてください。
  - 1つのノートは、その論点が単独で理解できる最小限の文脈（目安1〜3文）でまとめてください。
  - 情報量に対してカードを増やしすぎず、1つの話題につき主要な概念を優先してください。原文の全事実を網羅する必要はなく、重要度の低い細部や重複するカードは削ってかまいません。

  ## 空欄の作り方

  - すべての事実を空欄にしないでください。中心となる用語・関係・理由・処理の流れを空欄にし、説明をつなぐ部分は地の文として残してください。
  - 列挙や対比では、片方だけを空欄にせず、対になる項目も同じ cN でまとめて空欄にしてください。
  - 空欄を埋めた状態で、自然な日本語の文として読めるようにしてください。
  - 「のほかに」「前述の」「このドキュメントでは」など、前の文や資料全体に依存する表現を避け、各ノートが単独で意味が通るようにしてください。
  - 答えは単語だけでなく、節や文のレベルでもかまいません。自由記述で答えられる形を中心にしてください。

  ## 問題の種類と難易度

  - 次の二種類を出してください。
    - 普通の穴埋め問題: 用語・項目・短い言い回しを問う。
    - 記述式の穴埋め問題: 理由・関係・定義・処理の流れを文章で答える。
  - 記述式を中心にし、普通の穴埋めは補助的に入れてください（目安: 記述式が6〜7割以上）。
  - 単に単語を聞くような簡単な問題ではなく、自由記述で穴埋めする問題を中心にしてください。
  - 1つのノートの中に、普通の穴埋めと記述式の穴埋めを混在させてかまいません。

  ## 重複の禁止

  - 異なる cN のカード間では、同じ答え・似た答えになる空欄を2か所以上作らないでください。
  - 同じ cN の中で、関連する複数の空欄（似た答案を含む）をまとめることは許可します。これらは1枚のカードとして同時に復習されるためです。

  ## 原文の扱い

  - 原文の意味を変えないでください。原文にない事実を追加しないでください。
  - 直訳調の構文は、問題文として自然な日本語に整えてください。
  - 原文の論理展開（定義 → 具体例 → 注意点など）を保ち、ノート内の文の順序を大きく変えないでください。

  ## ヒント

  - ヒントは、答えの種類や範囲を示す必要がある場合だけ付けてください。文脈から明らかな場合は省略してかまいません。

  +Thought · 7.2s
  追記したプロンプト全文です。decks/regex/introduction.prompt.md に保存しました。
  # 穴埋め問題作成プロンプト（regex/introduction）

  次のルールに従って `decks/regex/introduction.html` から穴埋め問題を作成してください。

  ## 出力形式

  - 問題セットは CSV 形式で出力してください。
  - 1行を1ノートとし、各ノートは1つの CSV フィールドとして出力してください。カンマ・改行・ダブルクォートを含む場合は RFC 4180 に従って引用してください。
  - 穴埋め箇所は `{{c1::答え::ヒント}}`、`{{c2::答え::ヒント}}` のように番号を付けてください。
  - 各 cN から1枚のカードが生成されます。同じ cN を複数の空欄で使うと、それらは同じカードの複数の空欄として同時に復習されます。
  - 1ノートに複数の文を含めてかまいません。1文1カードに分割しないでください。

  ## カードのまとまり

  - 1つの cN は、1つの「理解してほしい論点」に対応させてください。その論点を構成する複数の事実・空欄は、同じ cN にまとめてください。
  - 同じ話題の隣接する文、因果関係・対比・列挙の関係にある文は、1つのノートにまとめてください。
  - 並列・列挙・対になる項目（例: 2種類の問い合わせ、2種類の文字列操作）は、同じ cN でまとめて1枚のカードにしてください。
  - 同じノート内でも、独立して復習する価値がある別の論点は、別の cN に分けてください。
  - 1つのノートは、その論点が単独で理解できる最小限の文脈（目安1〜3文）でまとめてください。
  - 情報量に対してカードを増やしすぎず、1つの話題につき主要な概念を優先してください。原文の全事実を網羅する必要はなく、重要度の低い細部や重複するカードは削ってかまいません。

  ## 空欄の作り方

  - すべての事実を空欄にしないでください。中心となる用語・関係・理由・処理の流れを空欄にし、説明をつなぐ部分は地の文として残してください。
  - 列挙や対比では、片方だけを空欄にせず、対になる項目も同じ cN でまとめて空欄にしてください。
  - 空欄を埋めた状態で、自然な日本語の文として読めるようにしてください。
  - 「のほかに」「前述の」「このドキュメントでは」など、前の文や資料全体に依存する表現を避け、各ノートが単独で意味が通るようにしてください。
  - 答えは単語だけでなく、節や文のレベルでもかまいません。自由記述で答えられる形を中心にしてください。

  ## 問題の種類と難易度

  - 次の二種類を出してください。
    - 普通の穴埋め問題: 用語・項目・短い言い回しを問う。
    - 記述式の穴埋め問題: 理由・関係・定義・処理の流れを文章で答える。
  - 記述式を中心にし、普通の穴埋めは補助的に入れてください（目安: 記述式が6〜7割以上）。
  - 単に単語を聞くような簡単な問題ではなく、自由記述で穴埋めする問題を中心にしてください。
  - 1つのノートの中に、普通の穴埋めと記述式の穴埋めを混在させてかまいません。

  ## 重複の禁止

  - 異なる cN のカード間では、同じ答え・似た答えになる空欄を2か所以上作らないでください。
  - 同じ cN の中で、関連する複数の空欄（似た答案を含む）をまとめることは許可します。これらは1枚のカードとして同時に復習されるためです。

  ## 原文の扱い

  - 原文の意味を変えないでください。原文にない事実を追加しないでください。
  - 直訳調の構文は、問題文として自然な日本語に整えてください。
  - 原文の論理展開（定義 → 具体例 → 注意点など）を保ち、ノート内の文の順序を大きく変えないでください。

  ## ヒント

  - ヒントは、答えの種類や範囲を示す必要がある場合だけ付けてください。文脈から明らかな場合は省略してかまいません。
  補足: 改訂版では以前の「マッチさせたい文字列の集合を指定できる」カードが削られているため、「原文の全事実を網羅せず、重要度の低い細部は削ってよい」という指示も入れています。この削除が意図と違う場合は、その一文を外してください。共有プロンプト（.github/prompts/create-anki-cloze.prompt.md）側にも反映したい場合は言ってください。
  ```
]
#prompt_box()[
  \@decks/regex/introduction_revised.csv に今回のカードを調整したバージョンを用意しました。このデッキのカードと以前に作った \@decks/regex/introduction.csv を比較して、このカードを作成するのに不足していた情報をプロンプトに書き足してください
]
#answer_box()[
  ```
    decks/regex/simple-patterns.csv に作成しました。introduction.prompt.md の形式に従っています。
  - 10ノート / 16カード
  - 普通の穴埋め 4カード、記述式 12カード（記述式中心）
  - 関連する事実は同じノートにまとめ、同じ cN で同時に復習する構成
  - 例: *・+・? の回数は1カード、貪欲さとバックトラックは1カード、{m,n} の省略時の下限・上限は1カード
  - 異なるカード間で同じ・類似の答えはありません
  "多くの活字や文字はそれ自身とマッチしますが、{{c1::特殊文字（メタ文字）::例外となる文字}} はそれ自身にマッチせず、繰り返しや意味の変更などの特別な働きをします。"
  "`[` と `]` は {{c1::文字クラス::指定するもの}} を表し、マッチしたい文字の集合を指定します。文字は個別に並べても `-` で範囲を与えてもよく、`[abc]` と `[a-c]` は同じ集合を表します。クラス内部では `\` を除く特殊文字は特別な意味を失い、例えば `[akm$]` の `$` は {{c2::単なる文字として扱われる::クラス内での扱い}}。"
  "文字クラスの先頭に `^` を置くと、{{c1::リストにない文字にマッチする::補集合}} ようになります。一方、`^` がクラスの先頭以外やクラスの外にある場合は {{c2::特別な意味を持たない::位置による違い}}。"
  "バックスラッシュ `\` は、続く文字と組み合わせて {{c1::特殊シーケンス::表すもの}} を表したり、特殊文字をエスケープして {{c2::リテラルとしてマッチさせる::エスケープの目的}} ために使います。例えば `[` や `\` 自体は `\[` や `\\` と書きます。"
  "`\d` は {{c1::任意の十進数字::十進数字の集合}}（`[0-9]`）に、`\D` はその補集合にマッチします。`\s` は {{c2::任意の空白文字::空白文字の集合}}（`[ \t\n\r\f\v]`）に、`\S` はその補集合にマッチします。これらのシーケンスは文字クラスの内部にも書けます（例: `[\s,.]`）。"
  "`\w` は任意の英数文字および下線にマッチし、バイト列パターンでは `[a-zA-Z0-9_]` と等価です。Unicode パターンでは {{c1::Unicode データベースで letters とマークされた全文字::Unicodeでの対象}} にマッチします。`re.ASCII` を指定すると {{c2::より制限された定義になる::フラグの効果}}。`\W` は `\w` の補集合です。"
  "`.` は {{c1::改行文字を除く任意の文字::マッチするもの}} にマッチし、`re.DOTALL` を指定すると改行にもマッチします。「任意の文字」にマッチさせたいときに使います。"
  "`*` は前の文字を {{c1::0 回以上::* の回数}} 繰り返し、`+` は {{c1::1 回以上::+ の回数}}、`?` は {{c1::0 回または 1 回::? の回数}} の繰り返しにマッチします。例えば `ca*t` は `ct`・`cat`・`caaat` に、`ca+t` は `cat`・`caaat` に（`ct` にはマッチしない）、`home-?brew` は `homebrew` と `home-brew` にマッチします。"
  "`*` のような繰り返しは {{c1::貪欲（greedy）::性質}} で、エンジンは可能な限り多く繰り返し、後続が失敗すると {{c1::戻ってより少ない回数を試す::失敗時の動作}}。例えば `a[bcd]*b` を `abcbd` に試すと、最終的に `abcb` にマッチします。"
  "`{m,n}` は繰り返し回数が {{c1::最小 m 回、最大 n 回::意味}} であることを意味します。例えば `a/{1,3}b` は `a/b`・`a//b`・`a///b` にマッチしますが、0 個の `ab` や 4 個の `a////b` にはマッチしません。`m` を省略すると下限は {{c2::0::下限}}、`n` を省略すると上限は {{c2::無限::上限}} と解釈されます。"
  原文の崩れへの対応:
  - [akm$] の $ が '{TX-PL-LABEL}#x27;' になっていたため、$ として扱いました。
  - 貪欲マッチの例の結論文が 'abcd' でしたが、表の最終行に合わせて abcb としました。
  ```
]
なんと元の資料のミスを指摘してくれた。すごい。

ただ、"列挙や対比では、片方だけを空欄にせず、対になる項目も同じ cN でまとめて空欄にしてください。"があまり守られていない気がする。

カードを修正しているうちに、訳文のミスに気づいた。カードの内容に
```
"`\w` は任意の英数文字および下線にマッチし、バイト列パターンでは `[a-zA-Z0-9_]` と等価です。Unicode パターンでは {{c1::Unicode データベースで letters とマークされた全文字::Unicodeでの対象}} にマッチします。`re.ASCII` を指定すると {{c2::より制限された定義になる::フラグの効果}}。`\W` は `\w` の補集合です。"
```
というのがあった。しかし、より制限された定義になると言われても、何がどう制限されるのかがわからない。そこで、元の資料を確認してみた。
```
"Let's take an example: ``\\w`` matches any alphanumeric character.  If the "
"regex pattern is expressed in bytes, this is equivalent to the class ``[a-zA-"
"Z0-9_]``.  If the regex pattern is a string, ``\\w`` will match all the "
"characters marked as letters in the Unicode database provided by the :mod:"
"`unicodedata` module.  You can use the more restricted definition of ``\\w`` "
"in a string pattern by supplying the :const:`re.ASCII` flag when compiling "
"the regular expression."
msgstr ""
"一つ例をお見せしましょう: ``\\w`` は任意の英数字文字にマッチします。バイト列"
"パターンに対しては、これは文字クラス ``[a-zA-Z0-9_]`` と等価です。ユニコード"
"パターンに対しては、 ``\\w`` は :mod:`unicodedata` モジュールで提供されてい"
"る Unicode データベースで letters としてマークされている全ての文字とマッチし"
"ます。正規表現のコンパイル時に :const:`re.ASCII` フラグを与えることにより、 "
"``\\w`` を、より制限された定義で使うことが出来ます。"
```
原文は

``` You can use the more restricted definition of ``\\w`` in a string pattern by supplying the :const:`re.ASCII` flag when compiling the regular expression.```

となっていて、その訳は

``` 正規表現のコンパイル時に :const:`re.ASCII` フラグを与えることにより、 ``\\w`` を、より制限された定義で使うことが出来ます。```
と訳されている。
しかし、今回の文は

```
You can use the more restricted definition
```

であって、

```
You can use more restricted definition
```
ではない。`the`がついているので、この文は読者とすでに共有されている「より制限された定義」を指している。これは、手前の`[a-zA-Z0-9_]`を指していると取るしかないだろう。実際#link("https://docs.python.org/ja/3.15/library/re.html")[Pythonの`\w`のドキュメント]を見てもそう書いてある。

英文が分かりにくいことも否定できないが、誤訳は誤訳である。訳文をなるべく変えずに正しく訳すと

```
正規表現のコンパイル時に :const:`re.ASCII` フラグを与えることにより、 ``\\w`` を、より制限された方の定義で使うことが出来ます。
```

などになるだろう。ただこれでも分かりにくいので、

```
正規表現のコンパイル時に :const:`re.ASCII` フラグを与えることにより、 ``\\w`` を、より制限された方の定義(``[a-zA-Z0-9_]``)で使うことが出来ます。
```
くらいまで書き足すと、読者が混乱しないだろう。
#prompt_box()[
  ```
  @decks/regex/simple-patterns_revised.csv に今回のカードを調整したバージョンを用意しました。このデッキのカードと以前のカードを比較して、このようなカードを他の章でも作成できるように @decks/regex/introduction.prompt.md にあるプロンプトを調整してください。
  ```
]

#answer_box()[
  ```
  decks/regex/simple-patterns_revised.csv と以前の simple-patterns.csv を比較し、改訂版の意図を一般則として decks/regex/introduction.prompt.md に反映しました。
  比較から読み取った主な変化
  改訂版の例	一般則として追加したこと
  文字クラス と マッチしたい文字の集合 を同じ c1 に	定義を構成する複数の要素は同じ cN にまとめる
  「\ を除く特殊文字は特別な意味を失います」という規則自体を空欄に	用語だけでなく、中心となる規則・定義そのものも空欄にする
  ^ の補集合と「先頭以外では特別な意味を持たない」を同じ c1 に	規則と例外・注意点は同じ cN で対比して復習する
  \[ や \\ という具体構文も c2 に追加	具体例・構文も規則と同じ cN で空欄にしてよい
  \d と \s を同じ c1 に	並列する定義は同じ cN にまとめる
  \w の一般形・バイト列・Unicode を同じ c1 に	同じ記号・概念の複数の定義やバリエーションは同じ cN にまとめる
  re.ASCII の効果を「バイト列パターン時のマッチと同等」と具体的に	曖昧な言い換えを避け、原文の最も具体的な説明に合わせる
  \d〜\W の一覧ノートを追加	並列項目が3つ以上なら、一覧形式のまとめノートを作る
  数量子の「記号」と「回数」を別 cN に	まとめノートでは順方向・逆方向の2枚のカードを作る
  「試す」→「試します」	文体をです・ます調で統一する
  プロンプトの主な変更点
  - 汎用化: introduction.html 固定から「対象の章の HTML ファイル」に変更し、出力も <元のstem>.csv に。
  - 「まとめカードと逆方向カード」節を新設: 一覧形式のまとめノートと、記号↔意味・回数↔記号の両方向カードを明示。
  - 空欄の作り方を強化: 規則・定義そのもの、具体例・構文、規則＋例外を同じ cN で空欄にするルールを追加。
  - 重複禁止を調整: 同じ方向の重複は禁止しつつ、一覧として復習するまとめカードは例外に。
  - 原文の扱いに追記: 文字化けや明らかな誤記は文脈から補い、判断内容を作業メモに残す。
  - 作成手順を追加: 論点の列挙 → 規則・例外・例をまとめる → 一覧・逆方向カード → 最終確認。
  なお、改訂版の1行目は「特殊文字（メタ文字）」という用語だけを空欄にしたカードとして残っているため、「用語だけを空欄にするな」と一律にはせず、用語自体が主眼のカードでは用語だけでもよいと条件付きにしています。
  これで using-regular-expressions.html や more-pattern-power.html なども、同じ方針でカード化できます。
  ```

]
実は放っておいたらContext Limitに引っ掛かったらしいが、自動的にCompactionが働いてContextを圧縮してくれたようだ。正直ログをたどるまでCompactionに気が付かなかった。
#prompt_box()[
  ```
  では、そのプロンプトに従って次は @decks/regex/using-regular-expressions.html からカードを作ってください
  ```
]

ここで、分割したファイルが結構長いことに気づく。もう自分も読めない。この場での評価は諦めて、まずはカードをとりあえず作ってAnkiに取り込むことに専念する。

と思ったけど、せっかくだし別のセッションのやつにチェックさせたろ。

#prompt_box()[
  ```
  @decks/regex/introduction.prompt.md の内容に、 @decks/regex/using-regular-expressions_revised.csv が従っているか確認して、違反している点があったら修正して
  ```
]

#answer_box()[
  ```
    decks/regex/using-regular-expressions_revised.csv をプロンプトと照合し、違反していた点を修正しました。現在は 19ノート・28カード・71空欄 で、記述式のカードが約75%です。
  主な修正
  - 用語だけの空欄を減らした  
  re の役割、フラグの効果、IGNORECASE の条件・例外、ASCII の適用範囲など、規則・定義そのものも空欄にしました。
  - 規則と例外の片側だけを空欄にしていた箇所を統合  
  LOCALE の非推奨、ASCII の byte パターンでの扱い、VERBOSE の文字クラス内・エスケープ時、DOTALL の指定なしの場合などを同じ cN にまとめました。
  - 対比・並列を同じ cN に統合  
  findall()/finditer()、group()/start()/end()/span()、通常時と MULTILINE の ^/$ など。
  - コードのバッククォート漏れを修正  
  search() などのメソッド名、SyntaxWarning/SyntaxError、フラグ名、start/end など。
  - 不自然な日本語・文体を修正  
  「を…ために」「衝突する。」「引数に…加えたもの」などを自然なです・ます調に直しました。
  - 曖昧な答えを具体化  
  「整形して読みやすく」→「よりきれいで理解しやすくまとめる」、「以外」→「改行を除くすべての文字」、「4文字」→実際の4文字、など。
  - 不要なヒントを削除  
  ::役割 のような、文脈から明らかなヒントを外しました。
  - まとめカードを整備  
  メソッド一覧・Match メソッド一覧・フラグ一覧に、順方向と逆方向の2枚のカードを作りました。
  - 重複を削除  
  モジュールレベル関数の戻り値について、search()/prefixmatch() のカードと重複する記述を外しました。
  判断メモ
  - prefixmatch() は、原文 HTML が Python 3.15 の名称（以前は match()）を使っているため維持しました。Python 3.14 以前を対象にする場合は match() への置換が必要です。
  - 原文のフラグ表では ASCII の対象が \w・\b・\s・\d、詳細説明では \w・\W・\b・\B・\s・\S と異なるため、両方を合わせた \w・\W・\b・\B・\s・\S・\d に統一しました。
  - 原文の「これらの関数は None または Match オブジェクトを返す」は re.sub() には当てはまらないため、モジュールレベル関数のノートでは包括的な戻り値の記述を外し、search()/prefixmatch() のノートで扱いました。
  - 原文の「意味を意味を」「短かい」などの誤記は CSV には持ち込まず、文字化けもありませんでした。
  補足として、decks/regex/using-regular-expressions.csv は修正前の _revised.csv と同一内容のまま残しています（編集したのは _revised.csv のみです）。必要なら同じ内容に同期できます。
  ```
]
そうか、今度は評価が上手くいっているかを評価しないといけないのか。

VSCodeでdiffってどうやって見るんだっけ？

一つ目のファイルで右クリックして「比較対象を選択」、二つ目のファイルで右クリックして「選択項目を比較」を選ぶと、二つのファイルの差分が表示されるっぽい。初めて使った。

めっちゃクオリティがあがった！やっぱり人間と同じで、雑に作るー＞細部を詰めるの手順が大事なんだねぇ。

この手順を自動化したいので、

#prompt_box()[
  こんな感じで、カード作成、別のAIにreviseさせるステップをopencodeで自動化するにはどうしたらいい？
]
AIに丸投げする。
#answer_box()[
  ```
    おすすめは、「生成」と「レビュー」を別エージェント・別モデルに分け、機械チェックを間に入れる構成です。1つのプロンプトで全部やらせると、生成AIが自分の出力を甘く評価しやすいので、役割を分けた方が安定します。
  /anki <html> <prompt>
    └─ anki-orchestrator（進行役）
         ├─ anki-generator（モデルA）→ <stem>.csv
         ├─ validate_anki_csv.py → 機械チェック
         ├─ anki-reviewer（モデルB）→ <stem>_review.md + <stem>_revised.csv
         └─ 必要なら再レビュー（最大2回）
  1. エージェントを3つ作る
  .opencode/agents/anki-generator.md
  ---
  description: HTML 教材から Anki 穴埋め CSV を生成する
  mode: all
  model: opencode/deepseek-v4.1-flash-free#high
  steps: 24
  permissions:
    - action: edit
      resource: "*"
      effect: deny
    - action: edit
      resource: "decks/**/*.csv"
      effect: allow
    - action: shell
      resource: "*"
      effect: deny
    - action: subagent
      resource: "*"
      effect: deny
  ---

  あなたは Anki 穴埋め CSV の生成者です。

  - 指定されたプロンプトファイルを最後まで読み、そのルールに従う。
  - 指定された HTML の内容だけを根拠にする。原文にない事実を追加しない。
  - 出力は指定された `<stem>.csv` のみ。HTML、プロンプト、既存の `_revised.csv` は変更しない。
  - 1レコード1ノート、RFC 4180 に従って引用する。
  - 生成後、自分で CSV をパースして構文エラーがないか確認する。
  - 判断した点は最終メッセージに書く。不要なファイルは作らない。
  .opencode/agents/anki-reviewer.md
  ---
  description: Anki CSV を別モデルで独立レビューし、修正版を作る
  mode: all
  model: opencode/glm-5.3-flash-free#high
  steps: 24
  permissions:
    - action: edit
      resource: "*"
      effect: deny
    - action: edit
      resource: "decks/**/*_revised.csv"
      effect: allow
    - action: edit
      resource: "decks/**/*_review.md"
      effect: allow
    - action: shell
      resource: "*"
      effect: deny
    - action: subagent
      resource: "*"
      effect: deny
  ---

  あなたは Anki CSV の独立レビュアーです。生成には参加していません。

  - プロンプトファイル、元 HTML、レビュー対象 CSV を読む。
  - プロンプトの全ルールに照らして監査する。
  - 指摘は `blocking`（ルール違反）と `warning`（改善提案）に分ける。
  - 各指摘に、プロンプトの該当ルール、ノート番号、具体的な修正案を付ける。
  - `blocking` をすべて直した `_revised.csv` を書く。元の CSV は上書きしない。
  - `_review.md` にレビュー結果と修正の要点を書く。
  - プロンプトにない好みを追加しない。原文にない事実を要求しない。
  .opencode/agents/anki-orchestrator.md
  ---
  description: Anki CSV の生成→別モデルレビュー→検証を進行する
  mode: primary
  model: opencode/deepseek-v4.1-flash-free#high
  steps: 40
  permissions:
    - action: subagent
      resource: "*"
      effect: deny
    - action: subagent
      resource: "anki-generator"
      effect: allow
    - action: subagent
      resource: "anki-reviewer"
      effect: allow
    - action: shell
      resource: "*"
      effect: deny
    - action: shell
      resource: "python *validate_anki_csv.py*"
      effect: allow
  ---

  あなたは Anki カード作成パイプラインの進行役です。

  1. 対象 HTML とプロンプトを読み、出力 stem を決める。
  2. `anki-generator` に HTML・プロンプト・出力先を渡し、`<stem>.csv` を生成させる。
  3. `python scripts/validate_anki_csv.py <stem>.csv` を実行する。
  4. `anki-reviewer` に HTML・プロンプト・生成 CSV を渡し、`_review.md` と `_revised.csv` を作らせる。
  5. `python scripts/validate_anki_csv.py <stem>_revised.csv` を実行する。
  6. `blocking` が残っていれば、`_revised.csv` をもう一度レビューさせる。最大2回で打ち切る。
  7. 使用モデル、ノート数・カード数・空欄数、残った warning、差分の要点を報告する。

  禁止:
  - 元の `<stem>.csv` を上書きしない。
  - HTML やプロンプトを変更しない。
  - レビュアーにプロンプトにない好みを追加させない。
  2. /anki コマンドを作る
  .opencode/commands/anki.md
  ---
  description: HTML から Anki CSV を生成し、別モデルでレビュー・修正する
  agent: anki-orchestrator
  ---

  対象 HTML: $1
  カード作成プロンプト: $2
  （$2 が空なら `decks/regex/introduction.prompt.md` を使う）

  `anki-orchestrator` の手順に従って、生成→検証→独立レビュー→修正→再検証を実行してください。
  TUI からはこう呼びます。
  /anki decks/regex/simple-patterns.html decks/regex/introduction.prompt.md
  3. 機械チェック用スクリプトを置く
  scripts/validate_anki_csv.py
  import csv
  import json
  import re
  import sys
  from pathlib import Path

  CLOZE = re.compile(r"\{\{c(\d+)::(.*?)\}\}", re.S)


  def validate(path: str) -> dict:
      errors, warnings = [], []
      with Path(path).open(encoding="utf-8", newline="") as f:
          rows = list(csv.reader(f))

      stats = {"notes": len(rows), "cards": 0, "blanks": 0}

      for i, row in enumerate(rows, 1):
          if len(row) != 1:
              errors.append(f"note {i}: expected 1 field, got {len(row)}")
              continue

          text = row[0]
          if not text.strip():
              errors.append(f"note {i}: empty note")
              continue

          if text.count("{{") != text.count("}}"):
              errors.append(f"note {i}: unbalanced cloze braces")

          matches = CLOZE.findall(text)
          if not matches:
              errors.append(f"note {i}: no cloze")
              continue

          ids = sorted({int(cid) for cid, _ in matches})
          if ids != list(range(1, max(ids) + 1)):
              errors.append(f"note {i}: non-contiguous cloze ids {ids}")

          for cid, answer in matches:
              if not answer.strip():
                  errors.append(f"note {i}: c{cid} has empty answer")
              if "{{" in answer or "}}" in answer:
                  errors.append(f"note {i}: c{cid} contains nested cloze")
              if "::" in answer:
                  warnings.append(f"note {i}: c{cid} contains a hint")

          stats["cards"] += len(ids)
          stats["blanks"] += len(matches)

      return {
          "ok": not errors,
          "errors": errors,
          "warnings": warnings,
          "stats": stats,
      }


  if __name__ == "__main__":
      if len(sys.argv) != 2:
          print("usage: validate_anki_csv.py <file.csv>", file=sys.stderr)
          sys.exit(2)

      result = validate(sys.argv[1])
      print(json.dumps(result, ensure_ascii=False, indent=2))
      sys.exit(0 if result["ok"] else 1)
  これで、CSV の構文・cN の連番・空欄の抜けなどは機械的に弾けます。  
  「規則と例外が同じ cN か」「記述式が6〜7割あるか」といった意味的な判定は、レビュアーに任せます。
  4. レビュアーにはルール番号を引用させる
  レビュー結果を安定させるには、プロンプトの見出しに番号を振っておくと便利です。
  ID	ルール
  R1	出力形式・CSV 引用
  R2	カードのまとまり・cN の粒度
  R3	まとめカード・逆方向カード
  R4	空欄の作り方（規則・例外・対比）
  R5	問題の種類と難易度
  R6	重複の禁止
  R7	原文の扱い
  R8	ヒント
  レビュー結果の例:
  # Review: simple-patterns.csv

  ## Blocking
  - [R4] note 7: `findall()` と `finditer()` が別 cN。対比なので同じ cN にまとめる。
  - [R2] note 14: `LOCALE` の非推奨が地の文に残っている。同じ cN で空欄にする。

  ## Warnings
  - [R8] note 3: ヒント `::役割` は文脈から明らかなので省略可。

  ## Stats
  - notes: 19, cards: 28, blanks: 71
  5. 実行方法
  TUI:
  /anki decks/regex/simple-patterns.html decks/regex/introduction.prompt.md
  CLI（バッチ・CI）:
  opencode run --standalone --agent anki-orchestrator @"
  対象 HTML: decks/regex/simple-patterns.html
  プロンプト: decks/regex/introduction.prompt.md
  "@
  CI では --standalone を使い、利用プロバイダの API キーを secret で渡します。
  - run: opencode run --standalone --agent anki-orchestrator "対象 HTML: ... プロンプト: ..."
    env:
      OPENCODE_API_KEY: ${{ secrets.OPENCODE_API_KEY }}
  6. 品質を上げるコツ
  - レビュアーは生成者と別モデルにする  
  エージェントに model を明示しないと親のモデルを継承するので、必ず指定します。例では生成を DeepSeek、レビューを GLM にしています。可能ならレビューには一番強いモデルを使ってください。
  - レビュアーに CSV を直接直させない選択肢も持つ  
  最初は「レビュアーが _revised.csv を書く」2段階で十分です。厳密にやるなら、レビュアーは _review.md だけ書き、anki-fixer が _revised.csv を作り、別のレビュアーが再確認する3段階にします。
  - 元ファイルを上書きしない  
  生成は <stem>.csv、修正は <stem>_revised.csv。最後に git diff --no-index で差分を見て、人間が採用を決めます。
  - ループは最大2回で打ち切る  
  blocking が0になるか、2回修正したら終了。warning ではループしません。
  - 修正者は指摘された点だけ直す  
  「勝手に全文を書き直す」と、レビューのたびに内容がドリフトします。システムプロンプトで「指摘外の文章は変更しない」と明記します。
  - プロンプトは1箇所に置く  
  decks/regex/introduction.prompt.md を生成者・レビュアーの両方が読む形にすれば、ルール変更時に二重管理になりません。
  7. さらに自動化するなら
  - 個別コマンドも作る  
  /anki-generate、/anki-review、/anki-fix に分けておくと、途中だけやり直せます。
  - スキル化する  
  .opencode/skills/anki-card-authoring/SKILL.md に「プロンプトを読む→生成→validator→独立レビュー」の手順とチェックリストを置くと、別の章でも同じ流れを再利用できます。
  - プラグイン/SDK で完全自動化  
  何十冊も一括処理するなら、Plugin か SDK でセッションを作成し、生成→検証→レビューをプログラムから回す方法もあります。ただし通常は、今回の「コマンド＋サブエージェント＋validator」で十分です。
  この構成でよければ、このリポジトリに .opencode/agents/、.opencode/commands/、scripts/validate_anki_csv.py の雛形を実際に作成できます。生成モデルとレビューモデルだけ指定してください。
  ```
]
ほへー。
#prompt_box()[
  生成モデルはDeepSeek V4.1 Flash Freeで、レビューモデルはGLM 5.3 Flash Freeでお願いします。
]

#answer_box()[
  ```
    自動化を組みました。生成は DeepSeek V4.1 Flash Free、レビューは GLM 5.3 Flash Free を別エージェント・別モデルで実行します。どちらも #high バリアントを指定しています。
  作成したファイル
  ファイル	役割
  .opencode/agents/anki-generator.md	下書き CSV を生成（DeepSeek）
  .opencode/agents/anki-reviewer.md	元資料とプロンプトを読み直して独立レビュー（GLM）
  .opencode/agents/anki-orchestrator.md	生成 → 検証 → レビュー → 検証を統括
  .opencode/commands/anki.md	/anki コマンド
  .opencode/README.md	使い方と出力規約
  scripts/validate_anki_csv.py	構造検証スクリプト
  scripts/README.md	検証スクリプトの説明
  使い方
  TUI で次のように実行します。
  /anki decks/regex/simple-patterns.html
  decks/regex/ 配下なら decks/regex/introduction.prompt.md を自動で使います。別のプロンプトを使う場合:
  /anki decks/regex/simple-patterns.html decks/regex/introduction.prompt.md
  出力は次の3つです。
  - <stem>_draft.csv — 生成担当の下書き
  - <stem>_review.md — 独立レビュー結果
  - <stem>_revised.csv — レビューを反映した修正版
  既存の <stem>.csv は上書きしません。既存の <stem>_revised.csv がある場合は確認し、必要なら <stem>_ai_revised.csv / <stem>_ai_review.md に退避できます。
  構造検証は単体でも実行できます。
  python scripts/validate_anki_csv.py decks/regex/simple-patterns_revised.csv
  スモークテスト結果
  decks/regex/common-problems.html で実際に通しました。
   	notes	cards	blanks	構造検証
  下書き	10	17	32	ok: true
  修正版	11	19	38	ok: true
  レビュー結果は must-fix 0件 / should-fix 2件 で、どちらも修正版に反映されました。
  - 非貪欲数量子のまとめノートを1つ追加（順方向・逆方向の2枚のカード）
  - translate() の中心的な規則部分を空欄化
  残課題として、レビュアー推定の記述式比率が 約55〜60% で、目安の「6〜7割以上」の下限にわずかに届いていません。再発防止のため、レビュアーには「6割未満なら記述式の空欄を追加する」指示を追記済みです。
  既存ファイルへの影響
  前回修正した decks/regex/using-regular-expressions_revised.csv は変更していません（19 notes / 28 cards / 71 blanks のまま）。
  テスト用に次のファイルが残っています。不要なら削除します。
  - decks/regex/common-problems_draft.csv
  - decks/regex/common-problems_review.md
  - decks/regex/common-problems_revised.csv
  なお、オーケストレーターはモデル未指定でセッションのモデルを継承します。今回の CLI スモークテストでは既定の big-pickle が使われ、最終報告の日本語に軽微な乱れがありました。生成・レビュー本体は指定モデルで正常に動作しています。日本語の最終報告を安定させたい場合は、DeepSeek のセッションから /anki を実行してください。
  ```
]

出来たカードを眺める。

```
"HTML や XML を正規表現でパースするのは苦痛を伴います。素早く汚いパターンは大抵うまく動作しますが、HTML と XML は{{c1::正規表現が破綻する特別な例}}であり、全ての可能な場合にうまく動作する正規表現を書き上げると{{c1::パターンは非常に複雑なものになります}}。そのような作業には{{c1::HTML や XML のパーサ}}を利用しましょう。"
```

素早く、汚いパターン......？

こういう時は原文を確認するに限る。

```
msgid ""
"(Note that parsing HTML or XML with regular expressions is painful. Quick-"
"and-dirty patterns will handle common cases, but HTML and XML have special "
"cases that will break the obvious regular expression; by the time you've "
"written a regular expression that handles all of the possible cases, the "
"patterns will be *very* complicated.  Use an HTML or XML parser module for "
"such tasks.)"
msgstr ""
"(HTML や XML を正規表現でパースすることは苦痛を伴うものであることは記憶に留め"
"ておいて下さい。素早く、汚いパターンは大抵の場合うまく動作しますが、HTML と "
"XML は正規表現が破綻する特別な例です; 全ての可能な場合にうまく動作する正規表"
"現を書き上げたときには、パターンは *非常に* 複雑なものになります。そのような"
"作業をする場合には HTML や XML パーサを利用しましょう。)"
```
common casesとspecial casesの訳が根本的に間違っていた。

とりあえず、Google翻訳にかけてあげると、
```
（HTMLやXMLを正規表現で解析するのは非常に面倒です。手っ取り早いパターンで一般的なケースは処理できますが、HTMLやXMLには、通常の正規表現では対応できない特殊なケースが存在します。あらゆるケースに対応できる正規表現を作成しようとすると、パターンは非常に複雑になります。このような処理には、HTMLまたはXMLパーサーモジュールを使用してください。）
```
と出力された。これはおおよそ正しいだろう。

quick-and-dirty:手っ取り早い

こうして見ると、こんなに長い文章の翻訳を一瞬でしてくれるGoogle翻訳はすごいといまさらながら感心した。

誤訳を修正するためにPython.jp内の翻訳チャンネルを見ようとしたが、Python.jpのDiscordがリンク切れしていて入れなかった。入れてくれよ。

誤訳の修正はいったん置いておいて、それじゃあ最後にこのファイルをまとめて一つにしてもらおう。

ん？質問？え？カードがない？

あ、まってもう一個カード化するファイルがあったわ。

まさに負うたAIに教えられて浅瀬を渡る。だ。

もうオーケストレーションを起動するだけでOK。らくちん。

またなんか誤訳してる......

```
msgid ""
"Returns the string obtained by replacing the leftmost non-overlapping "
"occurrences of the RE in *string* by the replacement *replacement*.  If the "
"pattern isn't found, *string* is returned unchanged."
msgstr ""
"*string* 内で最も長く、他の部分と重複するところがない正規表現を "
"*replacement* に置換した文字列を返します。パターンが見つからなかった場合 "
"*string* は変更されずに返されます。"
```
leftmost = 最も長く？？？


#prompt_box()[
  ````
  regex内にある全体のカード群(regex/**_revised.csv)をPythonで一つのデッキにまとめて。
  - 各行はカードの内容、カード作成元のhtml、deck column, guid columnとして
  - csvの先頭には
  ```
  "#separator:Comma",
  "#html:true",
  "#notetype:穴埋め左寄せ",
  "#columns:テキスト,裏面追記",
  "#deck column: 3"
  "#guid column: 4"
  ```
    というヘッダーファイルを付けて。
  - 各デックのデッキ名は拡張子を除いた相対ファイルパスの/を::で置き換え、先頭に番号（何番目のファイルか）をつけ足したものにして
  - ファイルの順番は introduction_revised,simple-patterns_revised,using-regular-expressions_revised,more-pattern-power_revised,modifying_strings,common_problemsとしてください。
  - 詳細な仕様は @anki-manual/importing/text-files.md を見てください 
  ````
]

上手く結合してくれたので、Ankiで読み込んで使ってみる。

ぱっと見だと、穴埋め内で文章が終わるときに文体が敬体から常体に代わっているところがあったり、
ヒントが答えになってしまっている問題があったりするが、まだ初期のカードなので、後になればなくなるかもしれない。

相変わらず資料のミスに引っ張られて分かりにくくなっているところがある。原文も与えるべきだったか？

あと正規表現を書く問題がなかった。指示し忘れた......

まあ今回はなくていいか。文法自体は覚えることが多いだけでシンプルだしね。


Pythonの誤訳はどうしたものかと思っていたが、普通にPython Transifexで調べたら現在の場所が見つかった。

と思ったらなんかサイトがフリーズした。なんでや！

リロードしてもフリーズしては入れませんでした。ほんとうになんでや！

仕方ないのでissueとして立てたらちゃんと修正されました。

#link(
  "https://github.com/python-doc-ja/python-doc-ja/issues/1026",
)[Issue \#1026 Regular expression HOWTOの翻訳ミスの修正]

後はのんびりとAnkiで学習していこう。

といいつつ別のデッキ(Lean)も作り始めた。
== 学習中に見つけたこと

カードの独立性がまだ甘い。（前に比べたらまし）

markdownが変換されていない。（指示したら直してくれた）
