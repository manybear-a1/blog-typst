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
  token_pattern = re.compile("|".join(re.escape(token) for token in tokens))
  cloze_number = 0

  def replace_token(match):
      global cloze_number
      cloze_number += 1
      return "{{{{c{}::{}}}}}".format(cloze_number, match.group(0))

  converted_text = token_pattern.sub(replace_token, text)
  with output_path.open("w", encoding="utf-8", newline="") as output_file:
      writer = csv.writer(output_file, lineterminator="\n", quoting=csv.QUOTE_MINIMAL)
      writer.writerow(["Text", "Extra"])
      writer.writerow([converted_text, "原文全体を保持し、MathML 要素名と関連プロパティを穴埋め化"])

  with output_path.open("r", encoding="utf-8", newline="") as input_file:
      rows = list(csv.reader(input_file))

  print("rows:", len(rows))
  print("field_counts:", [len(row) for row in rows])
  print("source_characters:", len(text))
  print("cloze_markers:", len(re.findall(r"\{\{c\d+::", converted_text)))
  print("embedded_newlines:", "\n" in rows[1][0])
  print("first_cloze:", re.search(r"\{\{c\d+::.*?\}\}", converted_text).group(0))
  print("output:", output_path)
  '@ | python -