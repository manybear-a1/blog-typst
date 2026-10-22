# Anki 生成・レビュー パイプライン

HTML から Anki の穴埋め CSV を作り、別モデルで独立レビューして修正版を出す OpenCode の設定です。

## 使い方

```text
/anki decks/regex/simple-patterns.html
```

`decks/regex/` 配下の HTML では、カード作成プロンプトに `decks/regex/introduction.prompt.md` を自動で使います。別のプロンプトを使う場合は第2引数で指定します。

```text
/anki decks/regex/simple-patterns.html decks/regex/introduction.prompt.md
```

## 出力

元 HTML のディレクトリを `<dir>`、拡張子を除いたファイル名を `<stem>` とします。

| ファイル | 内容 |
| --- | --- |
| `<dir>/<stem>_draft.csv` | 生成担当の下書き |
| `<dir>/<stem>_review.md` | 独立レビューの結果 |
| `<dir>/<stem>_revised.csv` | レビューを反映した修正版 |

既存の `<dir>/<stem>.csv` は上書きしません。既存の `<dir>/<stem>_revised.csv` がある場合は、上書きせずに `<stem>_ai_revised.csv` と `<stem>_ai_review.md` に出力するか、既存ファイルを移動するかを確認します。修正版を採用する場合は、内容を確認してから手動で置き換えてください。

## 担当

| エージェント | モデル | 役割 |
| --- | --- | --- |
| `anki-generator` | `opencode/deepseek-v4.1-flash-free#high` | HTML から下書き CSV を生成 |
| `anki-reviewer` | `opencode/glm-5.3-flash-free#high` | 元資料とプロンプトに照らして独立レビューし、修正版を生成 |
| `anki-orchestrator` | セッションのモデル | 生成・検証・レビューの順序を統括 |

生成担当とレビュアーは別モデルです。レビュアーは生成担当の説明を参照せず、元資料 HTML とプロンプトを読み直します。

## 構造検証

```powershell
python scripts/validate_anki_csv.py decks/regex/simple-patterns_revised.csv
```

結果は JSON です。`ok` が `true` なら構造エラーはありません。`warnings` は終了コードに影響しません。

## 再試行

- 生成担当の構造修正: 最大2回
- レビュアーの構造修正: 最大1回
- それでも直らない場合は、途中成果物を残して停止します。

## 権限

- 生成担当は `*_draft.csv` だけを書き込めます。
- レビュアーは `*_revised.csv` / `*_review.md`（衝突回避時は `*_ai_revised.csv` / `*_ai_review.md`）だけを書き込めます。
- 統括者は CSV を書き換えません。実行できるシェルは検証スクリプトだけです。
- 各エージェントは Web 検索・Web フェッチ・外部ディレクトリへのアクセスを拒否されています。
