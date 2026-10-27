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

上手くいった。スクリプト一つで完全に自動化できるようになった。これで、カードの収集・整理が一気にできる。

subagentのモデルを変えて別のテストをしたまま、誤って別のモデルにしていたことが発覚した。DeepSeek V4.1 Flash 1017でやり直す。どおりでやたら生成に時間がかかると思った。

```
{{c1::cannot have side effects such as modifying locations in memory, sending emails, or deleting files}} unless {{c1::the program's type says so}}."
```

やりすぎ！どうやって解くねん！

いかにして機械的にこういうのを検出するかだよな。

とりあえず、anki生成パイプラインを検証させる。

```
@anki/.opencode/README.md これは、ankiカード生成用csvを作成するためのパイプラインです。このパイプラインをレビューして、問題点を洗い出してください。分からないことがあれば、ユーザーに質問することをいとわないでください。
```
````
## Assistant

`.opencode/README.md` を起点に、agents・command・プロンプト・validator・merge skill・既存成果物まで確認し、dry-run と単体テストも実行しました。リポジトリは変更していません（`git status` は clean）。

結論として、**設計の骨格は良い**のですが、**命名規約と merge の入力解決に、実運用で事故るレベルの不整合**があります。特に「`_ai_revised.csv` に逃がす」運用と「GUID が行番号依存」の2つは、再インポート時にカードを壊します。

## 良かった点

- OpenCode V2 の `permissions` 配列、`steps`、`model: provider/model#variant` は有効な形式です。モデルIDも実在します（`opencode/deepseek-v4.1-flash-free`、`opencode/glm-5.3-flash-free`）。
- 生成担当とレビュアーを分け、レビュアーに生成担当の説明を見せない構成は妥当です。
- 統括者が構造検証を実行し、修正回数を制限する設計も良いです。
- 既存の regex 6章の `_revised.csv` はすべて `validate_anki_csv.py` で `ok: true`。
- merge の単体テスト9件は pass しました。

---

## 重大な問題

### 1. 生成プロンプトの出力先が `_draft.csv` と矛盾している

- `decks/regex/introduction.prompt.md:8` は「`<元のstem>.csv` に保存」と指示しています。
- 一方、`anki-generator.md:43` は「出力は必ず `*_draft.csv`」、`anki-generator.md:49` は「**カード作成プロンプトを最優先**」と指示しています。
- さらに `README.md:23` と `anki-orchestrator.md:52` は `_draft.csv` 前提です。

つまり生成担当は、**「最優先のプロンプト」に従って `simple-patterns.csv` を書こうとする**か、`_draft.csv` と `simple-patterns.csv` のどちらを書くかで迷います。`simple-patterns.csv` はまさに上書き禁止の既存ファイルで、権限でも拒否されるため、生成が失敗・停止する可能性が高いです。

**修正案**: プロンプト側を「出力先は呼び出し元が指定する。ファイル名を自分で決めない」に変える。少なくとも `<元のstem>.csv` という記述は削除してください。

### 2. `_ai_revised.csv` へのフォールバックが merge と噛み合っていない

`README.md:27` は衝突時に `<stem>_ai_revised.csv` / `<stem>_ai_review.md` を出すとしていますが、merge 側はこれを想定していません。

- `merge_revised_csvs.py:101-104` は `_revised` しか剥がさないため、`bar_ai_revised.csv` は `bar_ai.html` を探しに行きます。実際に再現しました：

```text
bar_ai_revised.csv + bar.html
→ source HTML not found: ...\bar_ai.html
```

- 仮に `--allow-missing-source` で通しても、`deck_name` / `guid_base` は CSV の stem を使うため、デッキ名と GUID が `_ai_revised` 入りになります。既存の `_revised` デッキとは別デッキ・別ノートとして認識され、**更新ではなく重複追加**になります。
- `merge-order.txt` にも `_ai_revised.csv` は載っていないため、章順も崩れます。
- `--pattern` は `*_revised.csv` なので、`_revised.csv` と `_ai_revised.csv` が両方あると**両方輸入**されます。

**修正案**: まず「1つの命名規約だけを使う」に寄せるのが安全です。衝突時は既存 `_revised.csv` を `archive/` などへ移動し、常に `_revised.csv` に出す。どうしても `_ai_` を残すなら、merge に「source stem のエイリアス」と「deck/GUID の正規化」を追加し、manifest も両対応にする必要があります。

### 3. merge が既存の `all_revised.csv` を入力として拾う

`discover_csvs` は「出力ファイルと完全一致するパス」だけを除外しています（`merge_revised_csvs.py:155-165`）。そのため、出力先を変えると既存の `all_revised.csv` が入力になります。

再現結果:

```powershell
# root を decks にすると Lean 側の all_revised.csv を拾って失敗
python .agents\skills\anki-deck-merge\scripts\merge_revised_csvs.py decks --dry-run
# error: ...\decks\lean\...\all_revised.csv: source HTML not found: ...\all.html

# 出力先を変えると regex 側の all_revised.csv を拾って失敗
python .agents\skills\anki-deck-merge\scripts\merge_revised_csvs.py decks\regex `
  --order decks\regex\merge-order.txt --output "$env:TEMP\regex-current.csv"
# error: ...\decks\regex\all_revised.csv: source HTML not found: ...\all.html
```

`--allow-missing-source` を付けると、今度は**全ノートが重複して出力**されます。`SKILL.md:17` の「出力ファイルは自動で除外」は、出力が1つだけ・既定名のときしか成り立ちません。

**修正案**: `all_*_revised.csv` を常に除外する、`--exclude` を追加する、または manifest にあるファイルだけを入力にする。少なくとも「出力名を変えたら既存出力が入力になる」ことは文書に明記すべきです。

同じ根っこで、`--pattern "*_draft.csv"` も動きません。`read_source_html` が `_revised` しか剥がさないため、`index_draft.csv` は `index_draft.html` を探して失敗します。`--pattern` を公開するなら、source stem の解決も pattern に合わせる必要があります。

### 4. GUID が「行番号」依存で、レビュアーのノート挿入に耐えない

`build_rows` は GUID を `...-001`, `...-002` の行番号で作っています（`merge_revised_csvs.py:222`）。`SKILL.md:66` は「並び順を変えても GUID は変わらない」としていますが、これは**ファイルの並び順**の話で、**章内のノート挿入・並べ替え**には耐えません。

実際に再現しました:

```text
変更前: 001 = A, 002 = B
先頭に NEW を挿入した後: 001 = NEW, 002 = A, 003 = B
```

レビュアーは「まとめカードを追加」するため、`common-problems` では実際に 10→11 ノートへ増えています。この状態で再インポートすると、**001 の復習履歴が NEW に引き継がれ、A は 002 に移動する**という誤った更新が起きます。

**修正案**: 行番号ではなく、内容ハッシュか永続 ID にする。ただし内容ハッシュは「文章を修正すると別カードになる」トレードオフがあります。理想は、CSV に不可視の安定 ID を持たせる、または merge が `guid-map.json` のようなサイドカーで「このノートにはこの GUID」を保持する方式です。少なくとも現状の「行番号 GUID」は、レビューでノートが増える前提と矛盾しています。

### 5. Markdown 変換が cloze の答えを壊す

`note_to_html` はノート全体をそのまま Markdown に通します（`merge_revised_csvs.py:90-94`）。cloze の答えを保護していないため、答えの中の Markdown 記法が変換されます。

再現:

```python
note_to_html('{{c1::a*b*c}}')   # -> '<p>{{c1::a<em>b</em>c}}</p>'
note_to_html('{{c1::<html>}}')  # -> '<p>{{c1::<html>}}</p>'  （生HTML）
note_to_html('{{c1::x & y}}')   # -> '<p>{{c1::x &amp; y}}</p>'
```

既存の regex ノートは記号をバッククォートで囲んでいるため今は助かっていますが、将来 `*` や `<` を含む答えが地の文で来ると壊れます。旧 `anki-cloze-author/scripts/generate_cloze_csv.py` の `markdown_to_html` は cloze をトークン化して保護しており、**新しい merge ではその保護が失われています**。

**修正案**: cloze をトークンに置換 → Markdown 変換 → トークンを戻す。答えは必要に応じて `html.escape` する。`test_merge_revised_csvs.py` に `a*b*c` や `<html>` の回帰テストを追加してください。

### 6. `normalize_markdown` がフェンスコード内に空行を挿入する

`normalize_markdown` は「前の行が通常行で、次の行がリスト行なら空行を入れる」処理を、コードフェンスを考慮せずに行っています（`merge_revised_csvs.py:72-87`）。

再現:

```text
説明
```regex
- not a list
1. not a list
```
```

` ```regex ` の直後に空行が挿入され、コードブロックの内容が変わります。正規表現やコード例を含むデッキでは実害が出ます。

**修正案**: フェンスの開始/終了を追跡し、フェンス内では空行挿入をしない。インデントコードブロックも同様に除外する。

---

## 高い重要度の問題

### 7. shell 許可が広すぎて、任意の Python 実行を許しうる

生成担当と統括者の shell 許可は `python *validate_anki_csv.py*` です（`anki-generator.md:17`、`anki-orchestrator.md:19`）。OpenCode のワイルドカードはコマンド文字列全体に掛かるため、例えば次のようなコマンドもマッチし得ます。

```text
python -c "任意のコード" scripts/validate_anki_csv.py
python evil.py scripts/validate_anki_csv.py
```

生成担当は**外部由来の HTML を読む**ため、HTML 内の指示文（プロンプトインジェクション）から任意コード実行に到達する経路になり得ます。現状の regex HTML は安全そうですが、パイプラインとしては境界が弱いです。

**修正案**: `python scripts/validate_anki_csv.py *` のように先頭を固定する。`py` も使うなら別ルール。`-c` / `-m` を明示的に拒否する。可能なら shell ではなく専用ツール/ラッパーにする。

### 8. merge が validator を再利用していない

`read_notes` は「1フィールド」「空でない」「`{{` と `}}` の数が一致」しか見ません（`merge_revised_csvs.py:48-69`）。そのため、次のような CSV も merge を通ります。

- `{{c2::x}}` だけ（c1 がない）
- `{{c1::}}`（空の答え）
- cloze が1つもないノート（警告のみ）

構造検証は章単位では行われますが、merge 単体では保証されません。`--pattern` を変えたり、手で `_revised.csv` を編集した場合に効いてきます。

**修正案**: `validate_anki_csv.py` の `validate()` を import して、入力ごとに `ok` を確認して失敗する。テストも追加。

### 9. 2列目に「元 HTML 全体」を入れる設計は、容量とスタイルの面で危険

`read_source_html` は元ファイル全体を返します（`merge_revised_csvs.py:97-117`）。regex の章は `<section>` 断片なのでまだ良いですが、Lean の `index.html` は完全な HTML ページで、`<style>` や `<footer>` を含みます。

実測:

- `decks/lean/.../all_revised.csv` の2列目は `<!DOCTYPE html>` から始まり、1ノートあたり約17.8KB、`<style>` を含む。
- regex でも `using-regular-expressions` は1ノートあたり約45KB、`more-pattern-power` は約36KB。`all_revised.csv` は3MB。
- 同じ章の HTML が全ノートに複製されるため、Anki のコレクションも CSV も肥大化します。

`<style>` がカード側の CSS に影響する可能性もあり、Anki の表示が崩れるリスクがあります。README に「2列目に元 HTML 全体」と明記されているので意図的なのかもしれませんが、**この設計で良いかは確認したい点**です。

**修正案**: `--source-mode full|section|none` を追加し、既定を `<section>` / `<main>` 抽出にする。`<style>` / `<script>` / `<footer>` を除去する。あるいは2列目は「出典リンク＋短い抜粋」にする。

### 10. レビュアーの独立性・検証が、運用上まだ弱い

- レビュアーには「汎用スキルよりプロンプトを優先する」という指示がありません。`anki-card-creation` スキルは「atomic prompts」などを勧めるため、regex プロンプトの「1〜3文にまとめる」「同じ cN に複数空欄」と衝突し得ます。生成担当には `anki-generator.md:50` の優先指示がありますが、レビュアーにはありません。
- レビュアーは既存の `<stem>.csv` や過去の `_revised.csv` を read できます。独立レビューのはずが、過去の修正版に引きずられる可能性があります。
- 下書きのハッシュやスナップショットがありません。既存の `index_review.md` には「レビュー開始直後の読み取りでは…直後に再読した下書きでは…」という記述があり、レビュー中に下書きが変わったように見える（またはモデルがそう認識した）形跡があります。
- 統括者は「must-fix が revised に反映されたか」「review の件数が正しいか」を diff で検証していません。`index_review.md` は「`index.csv` は未変更」と書いていますが、そのファイルは存在しません。レビューの主張をそのまま最終報告に載せると、誤報が残ります。

**修正案**: レビュアーにもプロンプト優先を明記。`skill` を deny するか、許可するスキルを限定。過去の `_revised` / `<stem>.csv` の read を deny。下書きの SHA-256 を渡し、レビュー前後で一致を確認。draft と revised の diff を取り、must-fix 件数と突き合わせる。レビュー結果に JSON frontmatter（must_fix, should_fix, notes, cards, blanks）を付ける。

### 11. 権限のスコープが「対象章」に閉じていない

生成担当は `decks/**/*_draft.csv`、レビュアーは `decks/**/*_review.md` / `decks/**/*_revised.csv` を許可されています。つまり、**別章の成果物も上書き可能**です。プロンプトインジェクションやモデルの取り違えで、`common-problems_revised.csv` を別章のレビュー中に壊せます。

また、`decks/**/*_draft.csv` は glob の解釈によっては `decks/foo_draft.csv`（deck 直下）にマッチしない可能性があります。実際、README のパス規約は `<dir>` を任意のディレクトリとしているのに、権限は `decks/` 配下に固定です。`decks/` 以外の HTML を渡すと、読み取りはできても書き込みが拒否されます。

**修正案**: 実行ごとの一時ディレクトリ（例: `decks/regex/.runs/<run-id>/`）に出力し、権限をそこに限定する。少なくとも `decks/*_draft.csv` も許可する。入力 HTML が `decks/` 配下であることを統括者が検証する。

### 12. 再試行ルールと steps が矛盾・不足気味

- 生成担当は「検証が通るまで書き込みと検証を繰り返す」（`anki-generator.md:78-79`）ですが、統括者は「生成担当の修正は最大2回」（`anki-orchestrator.md:87`）です。生成担当が内部で何度も試すと、統括者の retry 回数と一致しません。
- 生成担当 `steps: 25`、レビュアー `steps: 35`。`more-pattern-power` は24ノート・111空欄あり、大きな章では途中で step 上限に達して**CSV が途中で切れる**可能性があります。
- 統括者は「出力が途中で切れていないか」を step 上限の観点では見ていません（validator が構造エラーとして拾う場合もありますが、最後のノートが欠けても気づかないことがあります）。

**修正案**: 生成担当の内部修正も最大2回に固定し、超えたら報告して終了。章が大きい場合は分割する。step 上限に達したら「未完」と明示する。出力のノート数が期待値と一致するか、章の見出し数などと照合する。

### 13. 「採用」の意味が曖昧で、merge の正本と一致していない

`README.md:27` は「修正版を採用する場合は、内容を確認してから手動で置き換えてください」と書いていますが、merge は `<stem>_revised.csv` を直接読みます。つまり:

- `<stem>.csv` を `_revised.csv` で置き換える運用なら、merge は置き換え後の `<stem>.csv` を読みません。
- `_revised.csv` が正本なら、`<stem>.csv` への手動置き換えは不要です。

さらに、`introduction_revised.csv`、`simple-patterns_revised.csv`、`using-regular-expressions_revised.csv` には `_draft.csv` / `_review.md` がありません。手動編集された `_revised.csv` が混ざっている可能性があり、レビュー保証の範囲が不明です。

**修正案**: 「merge の正本は `_revised.csv`」と明記し、`<stem>.csv` は旧版・手作業用として扱う。手動編集した `_revised.csv` には「reviewed ではない」ことを示すメタデータを付ける。または、採用時に `_revised.csv` を `<stem>.csv` にコピーし、merge は `<stem>.csv` を読むように統一する。

---

## 中・低の問題

- **`all_revised.csv` を validator に渡すと混乱する**: ヘッダ6行をノートとして数え、`ok: false` / 89 errors になります。内容自体は現在の6章83ノートと一致していますが、README の検証コマンドをそのまま実行すると誤解しやすい。ヘッダ付きファイルを検出して「章単位で検証してください」と返すべきです。
- **validator のテストがない**: `scripts/validate_anki_csv.py` には単体テストがありません。`c2` だけ、空答え、余分な `}}`、`::` を含む答え、CRLF などを固定テストにすべきです。
- **validator の限界**: 完全重複ノートしか警告しません。章をまたぐ重複、ヒントが答えを含むケース、答え内の `::`、stray brace などは検出できません。
- **章をまたぐレビューがない**: レビューは章単位です。デッキ全体の用語統一、章間の重複、章順の妥当性は機械的な merge 以外にチェックがありません。
- **出所メタデータがない**: どの HTML バージョン・プロンプト・モデル・実行日で作られたかが CSV に残りません。ソース HTML のハッシュをサイドカーに記録し、merge 時に照合するのが望ましいです。
- **旧パイプラインの残骸**: `.github/prompts/create-anki-cloze.prompt.md` は存在しない `/anki-cloze-author` を呼んでいます。`.agents/skills/anki-cloze-author` には `SKILL.md` がなく、`generate_cloze_csv.py` は `index.csv` / `index.md` / `index_cloze.csv` をハードコードしています。README の「正本」とも衝突するため、削除かアーカイブを推奨します。
- **リポジトリ衛生**: `__pycache__` が追跡され、`all_revised.csv` が3MBで追跡されています。生成物を記録する方針なら意図的ですが、差分レビューが重くなります。CI（validator テスト + merge テスト + 変更された `_revised.csv` の検証）もありません。
- **パスに空白があると validator が壊れる**: エージェント指示の `python scripts/validate_anki_csv.py <path>` は引用されていません。`decks/my deck/foo_draft.csv` のようなパスで引数が分割されます。`"<path>"` にしてください。
- **`--output` の相対パスは cwd 基準**: 既定は root 基準ですが、`--output out.csv` は cwd に出ます。README/SKILL に明記するか、root 基準に統一してください。
- **デッキ名に `_revised` と全体連番が入る**: `regex::1. introduction_revised` のようになります。章を挿入すると以降のデッキ名が変わり、Anki 上でデッキ移動が起きます。番号は表示順のための意図的なものだと思いますが、`_revised` は利用者に見せる名前としては不自然です。`--strip-suffix` を検討してください。
- **`scripts/README.md` の統計例が古い**: `simple-patterns_revised.csv` を 20 notes / 30 cards / 75 blanks としていますが、実際は 11 / 17 / 43 です。
- **`Note <行番号>` が多義的**: ノートが複数行を含むため、CSV の物理行番号とノート番号が一致しません。レビューでは「ノート番号」に統一した方が安全です。

---

## 確認したいこと

修正方針が変わるので、次を確認させてください。

1. **merge の正本はどちらですか？**  
   `<stem>_revised.csv` を正本にして `<stem>.csv` への置き換えをやめるか、逆に `<stem>.csv` を正本にして merge 側を変えるか。個人的には `_revised.csv` 正本＋`<stem>.csv` は旧版、が単純でおすすめです。

2. **2列目に元 HTML 全体を入れるのは意図どおりですか？**  
   意図どおりなら、`<style>` / `<script>` の除去や `<section>` 抽出だけでも入れた方が安全です。不要なら「出典リンク＋短い抜粋」に変える提案をします。

3. **衝突時の `_ai_revised.csv` 運用は残しますか？**  
   残すなら merge を全面対応（source alias、manifest、deck/GUID 正規化）します。残さないなら「既存 `_revised` を archive へ移動してから再実行」に統一するのがおすすめです。

4. **GUID の安定性はどこまで必要ですか？**  
   「章内にノートを挿入しても、既存カードの復習履歴を維持したい」なら、行番号 GUID はやめる必要があります。内容ハッシュか永続 ID のどちらを許容できますか？

5. **パイプラインは `decks/` 配下専用ですか？**  
   専用なら入力を `decks/` に限定して明示的にエラーにする。汎用なら権限を `decks/**` 以外にも広げる必要があります。

6. **旧 `anki-cloze-author` / `.github/prompts` はまだ使いますか？**  
   使わないなら削除・アーカイブして、`.opencode/README.md` を唯一の正本にするのがおすすめです。

必要なら、上記のうち **1〜6（出力先・`_ai_revised`・merge の discovery・GUID・cloze 保護・コードフェンス）** から順に修正パッチを当てます。
````

草。


`````
パイプラインのレビュー指摘を反映し、関連テストと dry-run まで確認しました。
修正した主な問題
- 衝突時の挙動を統一: 既存の <stem>_revised.csv がある場合は、別名（_ai_revised.csv など）を作らず、衝突パスを報告して停止する仕様に変更。
- _revised.csv を正本化: <stem>.csv は旧版・手作業用として扱い、パイプラインでは更新しないことを明記。
- merge の入力探索を修正:
- 既存の all_revised.csv を入力から除外。
- --pattern "*_draft.csv" でも _draft を除いた元 HTML を解決。
- 出力先変更時に過去の結合結果を拾う問題を解消。
- fenced code の保護: コードフェンス内の - item や 1. item に空行を挿入しないよう修正。長いフェンス（````）内の短いフェンスも正しく扱います。
- merge と validator を統合: merge 時に scripts/validate_anki_csv.py と同じ構造検証を実行し、cloze の不整合があれば停止。
- validator を拡張:
- sha256 を JSON に追加。
- #separator: などのヘッダー付き結合ファイルを検出し、章単位の CSV を検証するよう明確なエラーを返す。
- シェル権限を縮小: python *validate_anki_csv.py* から python scripts/validate_anki_csv.py * に限定。
- レビュアーの独立性を強化:
- カード作成プロンプトを最優先。
- HTML 内の指示文をプロンプトインジェクションとして扱わない。
- 新規カード追加は must-fix / should-fix に必要な最小限。
- 下書きの sha256 を渡し、統括者がレビュー前後で照合。
- decks/ 専用化: 対象 HTML を decks/ 配下に限定。
- 旧ツールをアーカイブ: anki-cloze-author と旧 GitHub Copilot プロンプトを archive/legacy-anki-cloze/ に移動。
検証結果
- merge テスト: 14件 OK
- validator テスト: 6件 OK
- simple-patterns_revised.csv: ok: true、notes: 11 / cards: 17 / blanks: 43、sha256 出力を確認
- all_revised.csv: 結合済みファイルとして明確なエラーになることを確認
- decks 全体の merge dry-run: 7 CSV / 101 notes、既存 all_revised.csv を除外
- --pattern "*_draft.csv" の dry-run: 4 CSV / 63 notes
- merge-order.txt を使った regex の dry-run: 6 CSV / 83 notes、章順どおり
- git diff --check: 空白エラーなし
- テストで生成された __pycache__ は削除済み
残る前提・注意点
- GUID は章内のノート位置で決まるため、章内でノートを挿入・削除・並べ替えると、その位置以降の GUID が変わります。
- 2列目に元 HTML 全体を入れるため、結合 CSV は大きくなります。これはカード単体で学習できるようにするための意図的な仕様です。
- _draft.csv の merge は確認用です。デッキ名と GUID に _draft が入るため、本番は _revised.csv を使ってください。
- 既定の all_revised.csv は再生成時に置き換わります。残したい場合は --output を指定してください。
- 変更は未コミットです。コミットは作成していません。
`````


```
構造的な整理は完了したね！でもまだ問題があって、それは、どんな資料からもカードを作成してくれるようなパイプラインにしたいのですが、現状では資料ごとに毎回カード作成用のプロンプト（prompt.md）を入力として与えないといけないという問題があります。さらに、プロンプトを与えてるにも関わらず、自分の思った通りのカードができません。例えば、 @anki/decks/lean/fp-lean-master/fp-lean-master/book/html/introduction/index_revised.csv ではこういう問題が起きました。
- markdownで書いて欲しいのに・を使ってしまう
- 同じ文章からの穴埋め二題を作るときは、同じ文章の中で、一題目を{{c1::...}}、二題目を{{c2::...}}にしてほしいのに、同じ文章を複製して、{{c1::...}}をそれぞれで作ってしまった
- leanを学習したいのに、元にした本の特徴とか書式の問題まで作ってしまった。
こういう問題が起きる理由を、洗い出してください。
```

````
結論
一番の根本原因は、「パイプライン共通の仕様」と「その資料固有の学習方針」を、1枚の prompt.md に全部詰め込んでいることです。
そのため、
- 資料ごとにプロンプトが必要になる
- プロンプトをコピーすると、regex 用の表現や古い出力規則まで持ち込まれる
- プロンプトに書かれていない意図（Markdown、c1/c2 の使い方、学習対象の範囲）は、モデルの自然な推測に任される
- レビュアーも「プロンプトに忠実か」しか見ないため、プロンプトの穴を検出できない
という連鎖が起きています。
1. パイプライン側の原因
1-1. プロンプトが必須入力になっている
- anki-orchestrator は「元資料 HTML」と「カード作成プロンプト」の2つを必須で受け取ります。
- プロンプトが空の場合、自動で使うのは decks/regex/ 配下のときだけです。
- それ以外のデッキでは「プロンプトのパスをユーザーに確認する」動作になります。
- anki-generator も anki-reviewer も、入力としてプロンプトのパスを要求します。
つまり、資料を追加するたびにプロンプトを用意する設計になっています。
1-2. 汎用スキルがデフォルトになっていない
anki-card-creation という汎用スキルは存在し、内容も「学習成果を特定する」「原子性」「重複確認」など、今回の問題に効くことが書かれています。
しかし現状は、
- デッキ固有のプロンプトが最優先
- 汎用スキルは「衝突したらプロンプトに従う」という位置づけ
- プロンプトが無い場合は汎用スキルへフォールバックせず、ユーザーに確認して停止
となっています。汎用スキルを「既定の土台」として使う設計になっていません。
1-3. プロンプトの自動探索が regex 専用
現状の自動選択は decks/regex/introduction.prompt.md の1パターンだけです。
たとえば Lean 用のプロンプトは
decks/lean/.../book/html/introduction.prompt.md
にありますが、HTML の場所から近いプロンプトを探す仕組みはありません。そのため毎回手動で渡す必要があります。
1-4. プロンプトのコピーによる仕様のズレ
実際の Lean 用プロンプト decks/lean/.../book/html/introduction.prompt.md は、タイトルが 「穴埋め問題作成プロンプト（regex 共通）」 で、例も decks/regex/... になっています。
さらに、
- 出力先が <元のstem>.csv のままで、現在の _draft.csv と矛盾
- 「日本語の文体はです・ます調」とあるのに、原文も出力も英語
- Markdown の箇条書き指定がない
など、regex 用プロンプトをコピーした痕跡があります。
プロンプトが「最優先」とされている以上、この古い記述はそのまま生成品質に影響します。
2. プロンプト仕様の原因
2-1. Markdown で書くことが明示されていない
今回の index_revised.csv では、箇条書きが • で平坦化されています。
Lean tooling: • `elan` — ... • `lake` — ... • `lean` — ...
これは Markdown の - ではありません。
原因は、
- プロンプトは「箇条書きや改行を使ってかまいません」とだけ書いている
- 「Markdown の - を使う」とは書いていない
- 生成担当の指示も「バッククォートで囲む」だけで、ノート本文全体を Markdown で書くことを明示していない
- 元 HTML が <ul><li> なので、モデルがその見た目を • として再現した
- 「1行1ノート」と CSV の引用を意識して、改行入りの Markdown リストを避け、1行に • で詰めた
という複合です。
• はただの文字なので、merge しても <ul> になりません。validator も Markdown の箇条書きかどうかは見ていません。
2-2. 「ノート」と「カード」の関係が曖昧
プロンプトには、
- 同じ cN を複数の空欄で使うと1枚のカードになる
- 独立した論点は別の cN に分ける
- まとめノートは本文の説明ノートとは別に作る
- 順方向と逆方向を別々の cN にして、2枚のカードにする
と書かれています。
しかし、「同じ文から2枚のカードを作るときは、1つのノートに c1 と c2 を共存させる」とは書かれていません。
そのためモデルは、
- 順方向用の文を1行複製して {{c1::...}}
- 逆方向用の文をもう1行複製して {{c1::...}}
という形にしました。結果として、同じ文章が2ノートに複製され、それぞれが c1 になっています。
実際、index_revised.csv の 8行目と9行目は、ほぼ同じ一覧文を複製し、両方とも c1 を使っています。
これはモデルが c2 を使えないわけではありません。同じファイルの16行目では、1つのノート内で c1 と c2 を正しく使っています。つまり、要約カードの指示が「2枚のカード」と「別々の cN」と「別のノート」を混同させているのが原因です。
レビュアーも「一覧形式のまとめノートと、順方向・逆方向の2枚のカードがあるか」としか見ておらず、「2枚のカードが同じノート由来か」「文を複製していないか」をチェックしていません。
2-3. 「何を学習したいか」の範囲が定義されていない
プロンプトの「主要な論点を列挙する」「原文の全事実を網羅する必要はない」という表現は、何を残し、何を捨てるかの基準になっていません。
Lean の元 HTML には、Lean の言語仕様だけでなく、
- この本の対象読者
- 本の読み方
- Lean のインストール方法
- コードブロック・エラーブロックの表示規則
- Unicode の入力方法
- リリース履歴
- 著者
- ライセンス
が含まれています。
現状のプロンプトには「本のメタ情報や書式の説明は除外する」「学習対象の概念を優先する」といった指示がありません。そのためモデルは、HTML の <h2> をすべて「主要な論点」として扱ってしまいます。
実際、index_review.md でも
章の主要論点（Lean の位置づけ、4属性とその定義、対象読者2種、読み方、Getting Lean のツール一式、表記規約、Unicode 入力）はすべて網羅
と、本のメタ情報を「主要論点」として肯定的に評価しています。レビュアーも「学習目標に対する重要度」ではなく「原文を網羅しているか」で見ているわけです。
2-4. 元 HTML に本のメタ情報がそのまま入っている
元 HTML には、
- <header class="page-context">
- <meta name="verso-tags" ...>
- リリース履歴
- 著者情報
- ライセンス
- フッター
が含まれています。
パイプラインは HTML 全体を生成担当に渡すため、モデルはこれらも「カード化対象」と見ます。本文だけを抽出する、あるいは「このセクションは除外」と明示する仕組みがありません。
3. レビュー・検証側の原因
3-1. validator は構造しか見ていない
validate_anki_csv.py が見るのは、
- CSV が1フィールドか
- cloze の番号が連続しているか
- 空の答えがないか
- 完全重複ノートがないか
だけです。
以下は検出できません。
- • が Markdown の箇条書きになっていない
- 同じ文を複製して c1 を振り直している
- 本のメタ情報がカードになっている
- 学習目標に対して不要なカードが混ざっている
3-2. レビュアーは「プロンプトへの忠実さ」しか見ていない
レビュアーは別モデルで独立性はありますが、判定基準はプロンプトです。
プロンプトに、
- 「Markdown の - を使う」
- 「同じ文なら1ノートに c1/c2 を共存させる」
- 「本のメタ情報は除外する」
と書かれていなければ、レビュアーもそれを問題にしません。
実際、index_review.md は must-fix 0 で、should-fix も「まとめカードの追加」だけです。• の箇条書きも、本のメタ情報も、レビュアーは問題視していません。
つまり、生成担当とレビュアーが同じ不完全な仕様を共有しているため、独立レビューしても同じ盲点を共有するという構造になっています。
4. モデル側の自然な傾向
モデルは、明示されないと次のように振る舞いがちです。
- 1行1ノートという指示を見て、1カード1行と解釈する
- 2枚のカードを作るために、文を複製して c1 を振り直す
- HTML の <ul><li> を見て、Markdown の - ではなく • で箇条書きを表現する
- 「主要な論点」と言われたら、見出しを全部拾って網羅的にする
- 「原文に忠実に」と言われたら、本のメタ情報も残す
これらはモデルの異常ではなく、仕様が沈黙している部分をモデルの一般傾向で埋めているだけです。
5. 症状との対応
症状
• を使ってしまう
同じ文を複製して c1 を2回使う
本の特徴・書式のカードができる
資料ごとにプロンプトが必要
プロンプトを渡しても意図と違う
6. 根本原因を一言でいうと
「カード作成の共通契約」と「その資料で何を学ぶか」が分離されておらず、すべてを資料ごとのプロンプトに依存していることです。
その結果、
- プロンプトが無いと動かない
- プロンプトをコピーすると古い規則が混入する
- プロンプトに書いていない意図はモデルの推測になる
- レビュアーもプロンプトに書いていない問題は指摘できない
という状態になっています。
改善するなら、まず
1. 全デッキ共通の基底仕様（CSV、Markdown、c1/c2 のノート規則、禁止事項）
2. デッキ固有のプロフィール（学習対象、除外するメタ情報、言語、難易度）
3. プロンプト無しでも動く既定プロフィール
に分けるのが本質的です。今回の3つの症状は、すべてこの分離不足から説明できます。
````

````
新しい3層構成への移行が完了しました。プロンプト無しでも decks/ 配下の HTML からカードを作れる状態です。
変更内容
1. 共通仕様（全デッキ共通）
- .opencode/anki-card-spec.md を新規作成
- 1行1ノート、RFC 4180、UTF-8
- ノート本文は Markdown、箇条書きは -（• / ・ 禁止）
- 同じ文から複数カードを作る場合は、文を複製せず1ノート内の c1/c2
- まとめカードの順方向・逆方向も同じ一覧ノート内の c1/c2
- 学習範囲、除外対象、重複禁止、レビュー必須チェック
2. 既定プロファイル
- .opencode/anki-default-profile.md を新規作成
- プロファイルが無い資料でも、主題の概念・規則・手順に絞る
- 書名・著者・ライセンス・目次・表示形式・インストール手順などを既定で除外
3. デッキプロファイル
- decks/regex/introduction.prompt.md → decks/regex/deck-profile.md
- decks/lean/.../introduction.prompt.md → decks/lean/deck-profile.md
- Lean プロファイルでは、対象読者・読み方・著者・ライセンス・リリース履歴・表示規則・Unicode 入力・エディタ操作・インストール手順を明示的に除外
4. プロファイル解決
- scripts/resolve_anki_profile.py を新規作成
- 明示指定 → 最も近い deck-profile.md → 既定プロファイル の順で解決
- profile_source を explicit / auto / default で返す
- scripts/test_resolve_anki_profile.py を新規作成
5. パイプライン更新
- anki-orchestrator: プロファイルを自動解決し、共通仕様とプロファイルを生成・レビュー担当へ渡す
- anki-generator: Markdown、c1/c2、除外範囲の自己チェックを追加
- anki-reviewer: •、文の複製、除外対象、学習目標からの逸脱を must-fix 対象に追加
- /anki: 第2引数は任意のプロファイルに変更
- .opencode/README.md と scripts/README.md を更新
検証結果
テスト	結果
test_resolve_anki_profile.py	5 tests OK
test_validate_anki_csv.py	6 tests OK
test_merge_revised_csvs.py	14 tests OK
regex merge dry-run	6 CSVs / 83 notes
Lean merge dry-run	1 CSV / 18 notes
既定プロファイル解決	実際の HTML で profile_source: "default" を確認
実資料でのスモークテスト
Lean の introduction/index.html を、プロファイル指定なし相当の新構成で生成してみました。
- 6 notes / 9 cards / 23 blanks
- 構造検証 ok: true、errors / warnings なし
- 箇条書きはすべて -
- strict / pure / functional / dependent types は1ノート内の c1/c2
- 同じ文の複製なし
- 本のメタ情報・タイポグラフィ・インストール手順のカードなし
スモーク用の CSV は確認後に削除済みです。
注意点
- 既存の *_revised.csv は上書きしていません。
- コミットは作成していません。新規ファイルは未追跡、プロファイル移動はステージ済みです。
- archive/legacy-anki-cloze/ には旧プロンプトの記載が残っていますが、これはアーカイブ対象なので変更していません。
- レビュアーの実資料での通し実行はまだ行っていません。生成側のスモークテストと全構造テストは通過しています。
````
さあ、実際に Lean の introduction/index.html を、プロファイル指定なし相当の新構成で生成してみよう！
