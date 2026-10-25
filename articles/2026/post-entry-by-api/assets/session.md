# New session - 2026-10-25T03:03:34.333Z

**Session ID:** ses_e8efc8be4ffe1R50jIz3T1Y9rQ
**Created:** 2026/10/25 12:03:34
**Updated:** 2026/10/25 13:59:43

---

## User

@articles/2026/anki-cloze/anki-cloze2.html の中身を、hatenaブログに下書きとして投稿できるスクリプトを書いて。
エンドポイントはhttps://blog.hatena.ne.jp/manybear/manybear.hatenablog.com/atomとして、API keyは別で読み込むようにして。

---

## Assistant

`scripts/post_to_hatena.py` を作成しました。この HTML には `<style>` が無く、脚注も無いので、`div#takehere` の中身（11,772 文字）だけが送信されます。

## やったこと

- **記事の抽出**: HTML の警告どおり `div#takehere` の中身、`<style>` タグ、`<section role="doc-endnotes">` の中身だけを取り出します（位置を記録して原文をそのまま切り出すので、属性の引用符なども変わりません）
- **API キーの分離読み込み**: スクリプトには埋め込まず、次の順で読み込みます
  1. `--key-file PATH`
  2. 環境変数 `HATENA_API_KEY`
  3. `.hatena-api-key`（カレント → リポジトリ直下 → ホーム）。中身はキーだけ、または `HATENA_API_KEY=...`
- **AtomPub 投稿**: WSSE 認証（SHA1 + nonce）で `https://blog.hatena.ne.jp/manybear/manybear.hatenablog.com/atom/entry` に POST し、`<app:draft>yes</app:draft>` で下書きにします
- **安全策**: 送信前に生成 XML をパースして検証、`--dry-run` で送信内容をファイル出力、HTTP エラー時はレスポンス本文を表示
- `.gitignore` に `.hatena-api-key` / `.env` を追加、`readme.md` に使い方を追記

## 使い方

```sh
# 下書き投稿
python scripts/post_to_hatena.py articles/2026/anki-cloze/anki-cloze2.html --title "記事タイトル"

# 送信 XML の確認だけ
python scripts/post_to_hatena.py articles/2026/anki-cloze/anki-cloze2.html --title "記事タイトル" --dry-run

# 公開する場合
... --publish
```

`--title` を省略するとファイル名（`anki-cloze2`）になるので、指定をおすすめします（HTML 側にタイトルが入っていないため）。

ローカルのダミーサーバーで POST を実際に投げ、`/atom/entry` への送信・`X-WSSE` ヘッダ・`app:draft=yes`・CDATA 本文が正しく出ることを確認済みです。実投稿は API キーを用意して実行してください。

---

## User

使ってみたところ、二つほど問題点を見つけたので修正してください。
- 投稿はできるが更新ができない（下書きを一度上げた後、修正してもう一度上げると別の下書きとして挙げられてしまった）
- typファイルを更新した後にHTMLにコンパイルするのを忘れてしまうので、htmlファイルの代わりにtypファイルを引数に持って、typstのコンパイルも自動化して欲しい

---

## Assistant

2点とも修正しました（`scripts/post_to_hatena.py`）。

## 1. 更新できるようにした

- 投稿に成功すると、レスポンスの `Location`（メンバURI）を `.hatena-entries.json` に記録します
- 2回目以降は同じURIへ **PUT**（更新）します。新規POSTはしません
- `.typ` / `.html` のどちらを渡しても同じ記事として扱います（拡張子を除いたパスで記録）
- タイトルを省略すると前回のタイトルを引き継ぎます
- `--new` で明示的に別記事として新規投稿、`--entry-url URI` で更新先を指定

すでに手動で作ってしまった下書きを引き継ぐには、まず一覧からURIを調べます。

```sh
python scripts/post_to_hatena.py --list
```

表示された `https://blog.hatena.ne.jp/.../atom/entry/123` を指定して1回実行すれば、以降はその記事が更新対象になります。

```sh
python scripts/post_to_hatena.py articles/2026/anki-cloze/anki-cloze2.typ \
  --entry-url https://blog.hatena.ne.jp/.../atom/entry/123 --title "記事タイトル"
```

## 2. typ から直接投稿（自動コンパイル）

`.typ` を引数に取ると、投稿前に自動でコンパイルします。

```sh
python scripts/post_to_hatena.py articles/2026/anki-cloze/anki-cloze2.typ --title "記事タイトル"
```

- `typst compile --root <リポジトリ直下> --features html --format html <input.typ> <同名.html>` を実行（`/template/...` の絶対importに対応するため root はリポジトリ直下が既定）
- 出力先は既定で `.typ` と同じ場所の同名 `.html`（`--html-out` で変更可）
- コンパイル失敗時は typst のエラーメッセージを表示して投稿しません
- `.html` を渡したときに隣の `.typ` の方が新しければ警告を出します

## 動作確認

ローカルのダミーサーバーで、`typ → POST`、再実行で同じURIへの `PUT`、`.html` 指定でも同じ記事の `PUT`、`--new` での再投稿、`--list` の表示、`--dry-run` の更新判定まで確認済みです。`--dry-run` は状態ファイルを書き換えません。

なお、このリポジトリの `anki-cloze2.html` は `.typ` より古かったため、動作確認時に最新の内容で再生成されています（本文 24,911 文字）。

---

## User

だいぶ良くなったけど、まだ結構問題点があるね
- コードブロック内に別のmarkdownコードブロックの記法(```)があると、コードブロックが二重にネストされてしまう
- 記事に画像がある場合、その画像ははてなフォトライフ経由で上げたもののリンクを保存して、そのリンクで差し替えないといけない。
- 更新のために画像のURIも保存する必要があるため、記事に対応するURIを一つのjsonファイルで管理すると長くなりすぎてしまう。なので、各記事ごとに、記事に対応するURIとその記事に使っている画像のURIを保存するjsonを保存する形にしてほしい
- 保守性のために、post_to_hatena.pyを分割して欲しい

---

## Assistant

Now I understand the layout. Let me check the current state of the template's image handling, then restructure.



---

## Assistant

The article source confirms the root cause: Hatena stores entries in the blog's configured editing mode (Markdown here), so the HTML gets Markdown-parsed and fenced code blocks fire. I'll make the script detect the stored notation and adapt, plus add Fotolife uploads, per-article state, and split it into modules.



---

## Assistant

4 点とも対応しました。構成は `scripts/post_to_hatena.py`（薄い入口）＋ `scripts/hatena_blog/` 以下のモジュール群です。

## 1. コードブロックの二重ネスト

原因は、はてなブログの記事の記法が「ブログの設定 → 基本設定 → 編集モード」で決まっていて、AtomPub の `content type="text/html"` では変えられないことでした。Markdown モードのブログに HTML を送ると、`<pre>` の中の ``` が Markdown のフェンスとして解釈されます。

- 投稿・更新のレスポンスの `<content type>` から実際の記法を判定（`text/html` / `text/x-markdown` / `text/x-hatena-syntax`）
- Markdown と判定したら `<pre>` を、**中身のバッククォート連続数より長い**フェンス付きコードブロックに変換して自動で再送信（`markdown_compat.py`）
- フェンスの前後には空行を入れて、直前の HTML ブロックに飲み込まれないようにしました
- 判定結果は状態ファイルに保存するので、次回以降は最初から正しい形式で送ります

`anki-cloze2.html` で確認したところ、17 個の `<pre>` が 0 個になり、中に 3 連バッククォートを含むブロックは 4 連フェンスになっています。

## 2. 画像をフォトライフ経由に

- ローカルの `<img src>` をはてなフォトライフ（`https://f.hatena.ne.jp/atom/post`）へアップロードし、返ってきた `<hatena:imageurl>` で本文を差し替え（`fotolife.py` / `images.py`）
- アップロード結果（URL・SHA1・日時）を保存し、画像が変わっていなければ再アップロードせず同じ URL を再利用
- `--skip-images` で従来どおり src をそのまま送ることも可能

## 3. 記事ごとの JSON

`<記事名>.hatena.json` を記事の隣に保存します（例: `articles/2026/anki-cloze/anki-cloze2.hatena.json`）。

```json
{
  "entry_url": "https://blog.hatena.ne.jp/.../atom/entry/...",
  "title": "記事タイトル",
  "content_format": "markdown",
  "updated": "2026-10-25T...",
  "images": {
    "img/sample.png": {
      "url": "https://...",
      "sha1": "...",
      "uploaded": "2026-10-25T..."
    }
  }
}
```

旧 `.hatena-entries.json` に記録があれば、その記事の分だけ新ファイルへ引き継いでから旧ファイルを整理します。`anki-cloze2` の記録は移行済みです（旧ファイルは 1 件だけだったため、他記事の記録は失われていません）。

## 4. モジュール分割

- `cli.py`: 引数解析と投稿の流れ
- `atom.py` / `auth.py` / `http_client.py`: AtomPub・WSSE・HTTP
- `fotolife.py` / `images.py`: 画像
- `markdown_compat.py`: Markdown 向け変換
- `html_extract.py` / `state.py` / `typst.py` / `config.py` / `errors.py`

## 動作確認

ローカル HTTP サーバで以下を確認しました。

- 1 回目: フォトライフへアップロード → POST（HTML）→ レスポンスが `text/x-markdown` → フェンス変換して PUT で再送信
- 2 回目: 画像は再利用、同じ記事へ PUT 1 回だけ
- `--list` の表示
- 実記事の `--dry-run`（24,911 文字、既存記事の URI を引き継いで PUT 対象になること）

`readme.md` にも画像・状態ファイル・記法判定・ファイル構成を追記しました。

なお、`.hatena-api-key` が 0 バイトのままなので実 API での投稿はまだ試せていません。キーを書き込んでから、

```sh
python scripts/post_to_hatena.py articles/2026/anki-cloze/anki-cloze2.typ
```

で更新できます（初回だけ HTML で送って Markdown を検出し、自動で再送信します）。
