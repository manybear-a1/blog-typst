"""Regression tests for the reusable Anki cloze generator.

Set ``ANKI_CLOZE_SOURCE`` to a Markdown file when running the source-dependent
test. The other tests work with a small in-memory card set.
"""

import csv
import os
from pathlib import Path
import tempfile
import unittest

from generate_cloze_csv import (  # type: ignore[import-not-found]
    anki_headers,
    build_rows,
    default_output_path,
    write_csv,
)


SOURCE_PATH = Path(os.environ.get("ANKI_CLOZE_SOURCE", "getting_started.md"))


class GenerateClozeCsvTests(unittest.TestCase):
    def test_default_output_path_uses_source_stem(self):
        source = Path("mathml/getting_started.md")
        self.assertEqual(
            default_output_path(source),
            Path("mathml/getting_started_cloze.csv"),
        )

    def test_write_csv_adds_anki_headers_and_relative_tag(self):
        source = Path("mathml/example.md")
        rows = [("<p>{{c1::question}}</p>", "<p>extra</p>")]
        with tempfile.TemporaryDirectory() as temporary_directory:
            output = Path(temporary_directory) / "output.csv"
            write_csv(output, rows, source)
            content = output.read_text(encoding="utf-8")
            header_text, data_text = content.split("\n", 5)[:5], content.split("\n", 5)[5]
            written_rows = list(csv.reader(data_text.splitlines()))

        self.assertEqual(header_text, anki_headers(source))
        self.assertEqual(written_rows, [list(row) for row in rows])

    @unittest.skipUnless(SOURCE_PATH.exists(), "set ANKI_CLOZE_SOURCE to a source Markdown file")
    def test_source_generates_independent_html_notes(self):
        source = SOURCE_PATH.read_text(encoding="utf-8")
        rows = build_rows(source)
        self.assertEqual(len(rows), 13)
        self.assertTrue(all(len(row) == 2 for row in rows))
        self.assertTrue(all(row[0].startswith("<p>") for row in rows))
        self.assertTrue(all("{{c1::" in row[0] for row in rows))
        # MDN specific
        self.assertNotIn("EmbedLiveSample", "\n".join(field for row in rows for field in row))


if __name__ == "__main__":
    unittest.main()
