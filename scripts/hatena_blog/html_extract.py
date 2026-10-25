"""Typst が出力した HTML から、ブログへ貼る部分だけを取り出す。"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote

from .errors import HatenaPostError

VOID_ELEMENTS = {
    "area",
    "base",
    "br",
    "col",
    "embed",
    "hr",
    "img",
    "input",
    "link",
    "meta",
    "param",
    "source",
    "track",
    "wbr",
}

_IMG_SRC_RE = re.compile(
    r'(?P<prefix><img\b[^>]*?\bsrc\s*=\s*)(?P<quote>["\'])(?P<src>[^"\']*)(?P=quote)',
    re.IGNORECASE,
)
_REMOTE_SRC_RE = re.compile(r"^(?:(?:https?|data|ftp):|//)", re.IGNORECASE)


@dataclass
class ExtractedArticle:
    """HTML から取り出した投稿用の断片。"""

    body: str
    styles: list[str] = field(default_factory=list)
    endnotes: str | None = None

    def to_html(self) -> str:
        parts = [*self.styles, self.body]
        if self.endnotes:
            parts.append(self.endnotes)
        return "\n".join(part for part in parts if part.strip())


class _ArticleExtractor(HTMLParser):
    """``div#takehere`` / ``style`` / ``section[role=doc-endnotes]`` を切り出す。

    文字列を再構築すると属性の引用符などが変わってしまうため、
    ``getpos()`` から元テキストの絶対位置を求めて、その範囲をそのまま切り取る。
    """

    def __init__(self, text: str) -> None:
        super().__init__(convert_charrefs=False)
        self._text = text
        self._line_starts = [0]
        for index, char in enumerate(text):
            if char == "\n":
                self._line_starts.append(index + 1)
        # (tag, tag_start, inner_start, record) のスタック
        self._stack: list[tuple[str, int, int, dict | None]] = []
        self.styles: list[str] = []
        self.body: str | None = None
        self.endnotes: str | None = None

    # --- 位置計算 ---------------------------------------------------------
    def _abs_pos(self) -> int:
        line, offset = self.getpos()
        return self._line_starts[line - 1] + offset

    def _tag_end(self, pos: int) -> int:
        """``pos`` から始まるタグの終端（``>`` の次）を返す。"""
        quote: str | None = None
        for index in range(pos, len(self._text)):
            char = self._text[index]
            if quote is not None:
                if char == quote:
                    quote = None
            elif char in "\"'":
                quote = char
            elif char == ">":
                return index + 1
        return len(self._text)

    # --- HTMLParser のフック ---------------------------------------------
    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        tag = tag.lower()
        start = self._abs_pos()
        inner_start = self._tag_end(start)
        attributes = {name.lower(): value for name, value in attrs}

        record: dict | None = None
        if tag == "style":
            record = {"kind": "style", "start": start}
        elif tag == "div" and attributes.get("id") == "takehere":
            record = {"kind": "body"}
        elif tag == "section" and attributes.get("role") == "doc-endnotes":
            record = {"kind": "endnotes"}

        if tag in VOID_ELEMENTS:
            return
        self._stack.append((tag, start, inner_start, record))

    def handle_endtag(self, tag: str) -> None:
        tag = tag.lower()
        end = self._abs_pos()
        for index in range(len(self._stack) - 1, -1, -1):
            if self._stack[index][0] == tag:
                while len(self._stack) > index:
                    self._finish(self._stack.pop(), end)
                return
        # 対応する開始タグがない終了タグは無視する

    def _finish(self, entry: tuple[str, int, int, dict | None], end: int) -> None:
        _tag, start, inner_start, record = entry
        if record is None:
            return
        kind = record["kind"]
        if kind == "style":
            self.styles.append(self._text[record["start"] : self._tag_end(end)])
        elif kind == "body":
            self.body = self._text[inner_start:end]
        elif kind == "endnotes":
            self.endnotes = self._text[inner_start:end]


def extract_article(html_text: str) -> ExtractedArticle:
    """Typst の HTML からブログへ貼る部分だけを取り出す。"""
    extractor = _ArticleExtractor(html_text)
    extractor.feed(html_text)
    extractor.close()

    if extractor.body is None:
        raise HatenaPostError(
            'div id="takehere" が見つかりませんでした。Typst の HTML 出力か確認してください。'
        )
    if not extractor.body.strip():
        raise HatenaPostError('div id="takehere" の中身が空です。')

    return ExtractedArticle(
        body=extractor.body.strip(),
        styles=extractor.styles,
        endnotes=extractor.endnotes,
    )


# --- 画像 ---------------------------------------------------------------
def find_image_sources(html_text: str) -> list[str]:
    """``<img src>`` の値を、重複を除いて出現順に返す。"""
    sources: list[str] = []
    for match in _IMG_SRC_RE.finditer(html_text):
        src = match.group("src")
        if src not in sources:
            sources.append(src)
    return sources


def replace_image_sources(html_text: str, mapping: dict[str, str]) -> str:
    """``<img src>`` を mapping の URL に差し替える。"""

    def replace(match: re.Match[str]) -> str:
        src = match.group("src")
        return (
            f"{match.group('prefix')}{match.group('quote')}"
            f"{mapping.get(src, src)}{match.group('quote')}"
        )

    return _IMG_SRC_RE.sub(replace, html_text)


def is_remote_source(src: str) -> bool:
    """http(s) や data: など、ローカルファイルでない src か。"""
    return bool(_REMOTE_SRC_RE.match(src))


def resolve_image_path(src: str, *, base_dir: Path, root: Path) -> Path:
    """HTML の src をローカルファイルのパスに変換する。"""
    raw = unquote(src).split("#", 1)[0].split("?", 1)[0].replace("\\", "/")
    if not raw:
        raise HatenaPostError(f"画像の src が空です: {src!r}")
    if raw.startswith("/"):
        return (root / raw.lstrip("/")).resolve()
    return (base_dir / raw).resolve()
