---
description: HTML から Anki CSV を生成し、別モデルでレビュー・修正する
agent: anki-orchestrator
---

対象 HTML: $1
カード作成プロンプト: $2

カード作成プロンプトが空の場合は、対象 HTML が `decks/regex/` 配下なら `decks/regex/introduction.prompt.md` を使ってください。それ以外のデッキでは、プロンプトのパスをユーザーに確認してください。対象 HTML が空の場合は、作業を開始せず、使い方を短く案内してください。

このワークフローでは、生成物を `<stem>_draft.csv`、レビュー修正版を `<stem>_revised.csv`、レビュー結果を `<stem>_review.md` に保存し、既存の `<stem>.csv` は上書きしないでください。既存の `<stem>_revised.csv` がある場合は上書きせず、別名で出力するか、既存ファイルを移動するかをユーザーに確認してください。
