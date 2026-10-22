# validate_anki_csv.py

`decks/regex` で使っている、1行1ノート・1ノート1フィールドの Anki 穴埋め CSV を検証します。

```powershell
python scripts/validate_anki_csv.py decks/regex/simple-patterns_revised.csv
```

結果は JSON で出力されます。構造エラーがなければ終了コードは `0`、あれば `1` です。`warnings` は終了コードに影響しません。

```json
{
  "ok": true,
  "file": "decks/regex/simple-patterns_revised.csv",
  "errors": [],
  "warnings": [],
  "stats": {
    "notes": 20,
    "cards": 30,
    "blanks": 75
  }
}
```

検査内容:

- 各ノートがちょうど1つの CSV フィールドであること
- 空のノートがないこと
- 各ノートに穴埋めがあること
- `{{` と `}}` が対応していること
- cN が1から連番になっていること（同じ cN の複数空欄は許可）
- 空の答えやネストした穴埋めがないこと
- 空のヒント、ヒント内の追加の `::`、完全重複ノートを警告すること
