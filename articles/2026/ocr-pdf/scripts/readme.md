# pdf_to_html.py

Datalab API で PDF を HTML に変換します。画像も抽出し、HTML と同じ階層の `<出力名>_images/` に保存して `src` を書き換えます。

（初回のみ）Datalab Python SDK をインストールしてください。
```powershell
pip install datalab-python-sdk
```

実行例:
```powershell
python scripts/pdf_to_html.py decks/linear_algebra/text_linear_algebra.pdf
```

オプションを指定する例:
```powershell
python scripts/pdf_to_html.py input.pdf -o out/document.html --mode accurate --pages "0-19"
```

出力先を省略すると `<PDF名>.html` を PDF と同じディレクトリに書き出します。`-o` にディレクトリを渡すと `<PDF名>.html` をその中に作ります。結果は JSON で標準出力に表示されます（`output`、`images_dir`、`image_count`、`page_count`、`parse_quality_score`、`math_count` など）。

数式は Datalab の出力で `<math>…</math>`（ブロックは `<math display=\"block\">`）の中に生の LaTeX で入っているので、そのままでは表示されません。変換時に次のように置き換えて、MathJax 4 で表示できる形式にします。

- インライン数式 `<math>…</math>` → `\(…\)`、ブロック数式 `<math display=\"block\">…</math>` → `\[ … \]`
- 内側の LaTeX はそのまま保持します（`&amp;`、`&lt;`、`&gt;` のような HTML エンティティもデコードしません）
- 数式があるファイルにだけ MathJax の設定と loader（cdn.jsdelivr.net の `tex-chtml`）を `<head>` に注入します

既存の HTML を後から変換する場合も同じ関数を使えます。

```powershell
python -c "import sys; sys.path.insert(0, 'scripts'); import pdf_to_html; from pathlib import Path; p=Path('decks/linear_algebra/text_linear_algebra.html'); p.write_text(pdf_to_html.make_math_renderable(p.read_text(encoding='utf-8')), encoding='utf-8')"
```

API キーはコードに書かず、プロジェクトルートの `.env` から読み込みます（`.env.example` をコピーして設定）。`--env-file` で別ファイルを指定でき、環境変数 `DATALAB_API_KEY` が既にあればそちらが優先されます。

| オプション                        | 説明                                                               |
| --------------------------------- | ------------------------------------------------------------------ |
| `--mode`                          | `fast` / `balanced`（既定）/ `accurate`                            |
| `--pages`                         | ページ範囲。0 始まり（例: `"0-5,10"`）。`--max-pages` とは併用不可 |
| `--max-pages`                     | 処理する最大ページ数                                               |
| `--paginate`                      | ページ区切りを出力に含める                                         |
| `--no-images`                     | 画像を抽出・保存しない                                             |
| `--skip-cache`                    | キャッシュを使わず再変換する                                       |
| `--block-ids`                     | HTML 要素に `data-block-id` を付ける                               |
| `--compact`                       | 整形しないコンパクトな HTML を出力する                             |
| `--extras`                        | 追加機能（例: `"extract_links,extract_bookmarks"`）                |
| `--max-polls` / `--poll-interval` | ポーリング回数（既定 300）と間隔の秒数（既定 2）                   |
| `--env-file`                      | API キーを読む `.env` のパス                                       |

テスト（ネットワーク不要）:

```powershell
python scripts/test_pdf_to_html.py
```
