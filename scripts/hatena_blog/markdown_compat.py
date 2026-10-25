"""Markdown 記法で保存されるブログ向けの変換。

はてなブログは「ブログの設定 → 基本設定 → 編集モード」で記事の記法が決まり、
AtomPub の content type では変更できない。Markdown モードのブログに HTML を
送ると、HTML の ``<pre>`` の中の ``` が Markdown のコードフェンスとして
解釈され、コードブロックが入れ子になってしまう。

そこで Markdown モード向けには ``<pre>`` ブロックを、中身より長いフェンスを
使った Markdown のコードブロックへ変換する。それ以外の HTML はそのまま
Markdown に埋め込む（Markdown は生の HTML を通すため）。

フェンスの前後には空行を入れる。空行が無いと、直前の HTML ブロックの続きと
みなされてフェンスが Markdown として解釈されないことがあるため。
"""

from __future__ import annotations

import re
from html import unescape

_PRE_RE = re.compile(r"<pre\b([^>]*)>(.*?)</pre>", re.IGNORECASE | re.DOTALL)
_CODE_WRAPPER_RE = re.compile(
    r"^\s*<code\b([^>]*)>(?P<code>.*)</code>\s*$", re.IGNORECASE | re.DOTALL
)
_LANGUAGE_CLASS_RE = re.compile(
    r'class\s*=\s*"[^"]*\blanguage-([\w+#.-]+)', re.IGNORECASE
)
_LANGUAGE_DATA_RE = re.compile(r'data-lang\s*=\s*"([\w+#.-]+)"', re.IGNORECASE)


def _longest_run(text: str, char: str) -> int:
    longest = 0
    current = 0
    for value in text:
        if value == char:
            current += 1
            longest = max(longest, current)
        else:
            current = 0
    return longest


def _language(*fragments: str) -> str:
    for fragment in fragments:
        match = _LANGUAGE_CLASS_RE.search(fragment) or _LANGUAGE_DATA_RE.search(fragment)
        if match:
            return match.group(1)
    return ""


def pre_blocks_to_fences(html_text: str) -> str:
    """``<pre>`` ブロックを Markdown のフェンス付きコードブロックに変換する。"""

    def convert(match: re.Match[str]) -> str:
        inner = match.group(2)
        wrapper = _CODE_WRAPPER_RE.match(inner)
        code = wrapper.group("code") if wrapper else inner
        language = _language(match.group(1), wrapper.group(1) if wrapper else inner)

        text = unescape(code).replace("\r\n", "\n").replace("\r", "\n").strip("\n")
        fence = "`" * max(4, _longest_run(text, "`") + 1)
        return f"\n\n{fence}{language}\n{text}\n{fence}\n\n"

    return _PRE_RE.sub(convert, html_text)


def to_markdown_safe(html_text: str) -> str:
    """Markdown モードのブログでも壊れないように HTML を調整する。"""
    return pre_blocks_to_fences(html_text)
