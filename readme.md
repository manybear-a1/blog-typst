## ブログのTypstソースコード保管リポジトリ

ブログのHTMLを生成しているTypstのソースコードを保管しているリポジトリです。 [ブログはこちら](https://manybear.hatenablog.com/)

## はてなブログへ下書き投稿する

Typst のソース（`.typ`）をそのまま引数に渡すと、`typst compile` で HTML に書き出してから、`div#takehere` の中身・`<style>` タグ・脚注（`section[role=doc-endnotes]`）だけを取り出し、はてなブログ AtomPub API で下書きとして投稿します。コンパイル済みの `.html` を渡すこともできます。

```sh
python scripts/post_to_hatena.py articles/2026/anki-cloze/anki-cloze2.typ --title "記事タイトル"
```

一度投稿した記事は、記事の隣の `<記事名>.hatena.json` に記録され、2 回目以降は同じ記事の更新（PUT）になります。別記事として投稿したいときは `--new` を付けます。以前のバージョンが使っていた `.hatena-entries.json`（全記事を 1 ファイルで管理）に記録がある場合は、その記事の分だけを新しいファイルへ引き継ぎます。

### 画像

記事中の `<img src>` がローカルの画像を指している場合、はてなフォトライフへアップロードし、返ってきた URL に差し替えてから投稿します。アップロード結果（URL と SHA1）も `<記事名>.hatena.json` に保存するので、画像が変わっていなければ次回以降は再アップロードせず同じ URL を再利用します。

### 記法（Markdown / 見たまま）

はてなブログの記事の記法は「ブログの設定 → 基本設定 → 編集モード」で決まり、AtomPub の content type では変更できません。Markdown モードのブログに HTML を送ると、`<pre>` の中の ``` が Markdown のコードフェンスとして解釈され、コードブロックが二重にネストしてしまいます。

このスクリプトは投稿後のレスポンスの `<content type>` から実際の記法を判定し、Markdown モードなら `<pre>` を（中身のバッククォートより長い）フェンス付きコードブロックに変換して自動で再送信します。判定した記法は状態ファイルに保存するので、次回以降は最初から適切な形式で送ります。

### タイトルとソースへのリンク

生成された HTML に `<title>` があれば、その中身を記事タイトルとして使います（`--title` より優先）。無い場合は `--title` → 前回のタイトル → ファイル名の順で決めます。

記事末尾の「ソースコードのリポジトリはこちら」のリンクは、テンプレートではリポジトリのトップを指しています。投稿時に、生成元の `.typ` の GitHub URL（`https://github.com/.../blob/<現在のブランチ>/<リポジトリからのパス>`）へ置き換えます。`.html` を渡した場合も、隣に同名の `.typ` があればそちらへリンクします。

- `--dry-run`: 投稿せず、送信する XML を一時ファイルに書き出して確認する
- `--publish`: 下書きではなく公開記事として投稿する
- `--list`: 最近のエントリ（最大 7 件）とメンバURIを表示する
- `--entry-url URI`: 指定した記事を更新対象にする（手動で作った下書きを引き継ぐとき）
- `--skip-images`: 画像をアップロードせず、`src` をそのまま送る
- `--state-file PATH`: 状態ファイルの保存先を変える（既定: `<記事名>.hatena.json`）
- `--root PATH` / `--html-out PATH`: `typst compile` の `--root` と出力先を指定する

このスクリプトを使う前に手動で作った下書きを更新したい場合は、`--list` でメンバURIを調べてから `--entry-url` に渡してください。

### 状態ファイルの中身

```json
{
  "entry_url": "https://blog.hatena.ne.jp/manybear/manybear.hatenablog.com/atom/entry/...",
  "title": "記事タイトル",
  "content_format": "markdown",
  "updated": "2026-10-25T00:00:00Z",
  "images": {
    "img/sample.png": {
      "url": "https://cdn.image.st-hatena.com/...",
      "sha1": "…",
      "uploaded": "2026-10-25T00:00:00Z"
    }
  }
}
```

### ファイル構成

`scripts/post_to_hatena.py` は入口だけで、実処理は `scripts/hatena_blog/` に分かれています。

- `cli.py`: 引数の解析と投稿の流れ
- `atom.py`: はてなブログ AtomPub（投稿・更新・一覧・記法の判定）
- `fotolife.py` / `images.py`: 画像のアップロードと URL の差し替え
- `markdown_compat.py`: Markdown モード向けの `<pre>` → コードフェンス変換
- `html_extract.py`: Typst の HTML からの抽出と画像パスの解決
- `state.py`: 記事ごとの状態ファイル（旧形式からの移行を含む）
- `repository.py`: リポジトリへのリンクを生成元ファイルの URL に置き換える
- `auth.py` / `http_client.py`: WSSE 認証と HTTP
- `typst.py`: `typst compile` の実行


API キーはスクリプトに埋め込まず、次の順で読み込みます。

1. `--key-file PATH`
2. 環境変数 `HATENA_API_KEY`
3. `.hatena-api-key`（カレントディレクトリ → リポジトリ直下 → ホーム）。中身は API キーだけを書く

hatenaの APIキーはPost by email を変更することで変更、取得できます。