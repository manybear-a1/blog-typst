//タイトル
#set document(title: "Example Document")

//コード表示
// raw(block:true)を指定しないとレンダリングされないことに注意すること。
// codlyはHTML出力に対応していなかった。
// #import "@preview/codly:2.0.0" as codly
// #import "@preview/codly-languages:0.1.8": codly-languages
// #show: codly.lang-set_(languages: codly-languages)
// #show raw.where(block: true): codly.new

//ブログ用テンプレートの読み込み
#import "/template/template.typ": *
#show: show_blog_with_typst

= LeanのAnkiカードを作りたい！
こないだ、正規表現のデッキを(DeepSeek V4.1 Flash 1017とGLM 5.3)で作ったら思いのほかうまくいったので、今度はLeanのAnkiカードを作ってみよう！まだ正規表現のデッキを学習中だけどね。
まずは、#link("https://lean-lang.org/functional_programming_in_lean/")[Functional Programming in Lean]と#link("https://lean-lang.org/theorem_proving_in_lean4/")[Theorem Proving in Lean 4]の内容をAnkiカードにして、Ankiで復習できるようにしたい。

さて、残念なことに、この本は全てLeanのコードで書かれているので、Ankiカードにするには、LeanのコードをそのままAnkiカードに貼り付けることになる。しかし、AnkiはHTMLしか受け付けないので、まずはLeanのコード（のうち、サンプルコードじゃない部分）をHTMLに変換する必要がある。

自分では正直どうやったらいいか見当もつかないが、まあAI(DeepSeek V4.1 Flash 1017)ならなんとかなるやろ！

なった。

```markdown
TPiL も FPLean と同じ方式で HTML 化し、変換プログラムを TPiL 側の book ディレクトリに独立して置きました。
出力
decks/lean/theorem_proving_in_lean4-master/theorem_proving_in_lean4-master/book/html/
  index.html                          # 本文 + 目次
  manifest.json                       # ページ一覧（順序・番号・アンカー・タグ）
  introduction/index.html             # 1. Introduction
  dependent-type-theory/index.html    # 2.
  ...
  the-conversion-tactic-mode/index.html  # 11.
  axioms-and-computation/index.html      # 12.
- 13 ページ（root 1 + 章 12）、合計 約 0.60 MB
- 各ページは CSS 埋め込みの完全自己完結（<script> / <link> / <img> なし）。外部参照は本文中の通常リンクのみ
- ページ分割は Main.lean の htmlDepth := 1 に一致、htmlSplit := .never の 3 章も反映
実行方法
cd decks/lean/theorem_proving_in_lean4-master/theorem_proving_in_lean4-master/book
python verso_to_html.py
Lean ツールチェーンは不要です。--out、--root、--html-depth、--verbose も使えます（TpiL 用のデフォルトは TPiL / 1）。使い方は book/README.md に追記しました。
検証（0 エラー）
- 13 ページ、各ページ <h1> は 1 個、番号が manifest と一致
- 内部リンク・ページ内アンカーがすべて解決
- :::comment / :::TODO / :::setup / :::leanFirst /  ``  / %%% / {include}` の残留なし
- Lean のツール用マーカー（PROOF_STATE: / ANCHOR: / -- BEGIN）はコードから除去済み
- /-- は Lean のドキュメントコメントとしてコードブロック内にのみ存在（正常）
- フッターは Theorem Proving in Lean 4 · Apache 2.0 と公開版 URL に変更
変換時の扱い
- :::comment / :::TODO は公開版に載らない編集メモなので出力しません
- :::setup は先頭のセットアップ用コードだけ落とし、説明文は残します
- save ブロックは後で使うコードの記録なので非表示
- proofState は独立したゴール表示ボックスにしています（公開版のようにコード中の該当行へ差し込む形ではありません。これは既知の差異です）
FPLean 側の修正
共通の変換処理を 2 点改善し、FPLean も再生成・再検証済みです（71 ページ / 0 エラー）。
- 空白付きディレクティブ（::: TODO）を認識するように修正（TPiL の Tactics にあった 1 箇所）
- リスト内などインデントされたコードフェンスの本文をフェンス位置基準でデデントし、コード先頭の余分な空白を解消
両スクリプトの差分は、docstring と以下の設定値だけに揃えてあります。
設定 | FPLean | TPiL
DEFAULT_ROOT | FPLean | TPiL
DEFAULT_HTML_DEPTH | 2 | 1
フッターのリンク | functional_programming_in_lean	 | theorem_proving_in_lean4
ライセンス表記	CC BY 4.0	Apache 2.0
```
ただ、本のコード自体はgitignoreで無視している影響で、スクリプトやHTML出力の結果もgitignoreで無視されてしまっているので、この部分を上手くgitignoreから外して、GitHubにpushする必要がある。

依頼したらなんとgit ignoreの設定を自動で修正して、そのままcommitしてくれた。すごい。

さて、ではまずは適当にintroduction/index.htmlを穴埋め問題にしてもらおう。

やべっ、プロンプトファイル用意し忘れた。そういえば共通の問題作成指示とか用意してなかったな。

とりあえず正規表現のときのプロンプトを流用するか。

間違えて目次ページを指定しちゃったwww。

改めて問題を作らせる。そろそろスキルを汎化させないとなぁ。

あ、問題の文章が日本語になっちゃった。今回は資料が英語だから、問題も英語にしておかないと、原文との対応が取りにくいな。

ちょっと見てみたが、revisedになってもけっこう粗が残っている。どうやら手順書に問題があるようだ。

```
"This book is intended for programmers who want to learn Lean but who {{c1::have not necessarily used a functional programming language before}}, so familiarity with functional languages such as Haskell, OCaml, or F# is {{c1::not required}}."
```
この本の特徴を覚えてどないすんねん。と思ったが、考えてみると、これまでの手順書では、このデッキの学習対象者の特徴を一切教えていなかった。確かに、司書さんとか向けならこういう情報も必要かもしれないが、Lean学習者向けのAnkiカードを作る場合は、本の特徴はあまり関係ない。カードの独立性がまだ甘いのも、このせいかもしれない。（なんらかの前提知識を仮定している）

```
- 「のほかに」「前述の」「このドキュメントでは」など、前の文や資料全体に依存する表現を避け、各ノートが単独で意味が通るようにしてください。
```
とはいえ、こういう指示は入っているんだけどな。

とりあえず指示書の整理を始める。

と言いたいところだが大変そうなので、まずはカードを集めて一つにまとめるスクリプトを書く方を優先することにした。指示書の整理は後回し。

前回の正規表現の時に使ったスクリプトとセッションがあるので、このデータをskill化する。
