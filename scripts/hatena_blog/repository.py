"""リポジトリ情報と、記事中のリポジトリリンクの書き換え。

テンプレートは記事の末尾に「ソースコードのリポジトリはこちら」というリンクを
置くが、リンク先はリポジトリのトップのままになっている。投稿時に、その
リンクを生成元ファイル（``.typ``）の GitHub 上の URL に置き換える。

Typst 側では生成元のファイル名を取得できないため、この処理はスクリプト側で行う。
"""

from __future__ import annotations

import re
import subprocess
from functools import lru_cache
from pathlib import Path
from urllib.parse import quote

from .config import (
    DEFAULT_REPOSITORY_BRANCH,
    DEFAULT_REPOSITORY_URL,
    REPO_ROOT,
)

_ANCHOR_HREF_RE = re.compile(
    r'(?P<prefix><a\b[^>]*?\s+href\s*=\s*)(?P<quote>["\'])(?P<href>[^"\']*)(?P=quote)',
    re.IGNORECASE,
)


def _git(*args: str) -> str:
    try:
        result = subprocess.run(
            ["git", "-C", str(REPO_ROOT), *args],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=10,
        )
    except (OSError, subprocess.SubprocessError):
        return ""
    if result.returncode != 0:
        return ""
    return result.stdout.strip()


@lru_cache(maxsize=1)
def repository_url() -> str:
    """GitHub のリポジトリ URL（``.git`` や認証情報は取り除く）。"""
    url = _git("remote", "get-url", "origin")
    if url.startswith("git@github.com:"):
        url = "https://github.com/" + url[len("git@github.com:") :]
    elif url.startswith("ssh://git@github.com/"):
        url = "https://github.com/" + url[len("ssh://git@github.com/") :]
    if url.endswith(".git"):
        url = url[: -len(".git")]
    if url.startswith("https://github.com/"):
        return url.rstrip("/")
    return DEFAULT_REPOSITORY_URL


@lru_cache(maxsize=1)
def repository_branch() -> str:
    """現在のブランチ名（取得できなければ ``main``）。"""
    name = _git("rev-parse", "--abbrev-ref", "HEAD")
    if name and name != "HEAD":
        return name
    return DEFAULT_REPOSITORY_BRANCH


def source_file_for_link(source: Path) -> Path:
    """リンク先に使うファイル。``.html`` なら隣の ``.typ`` を優先する。"""
    if source.suffix.lower() in {".html", ".htm"}:
        typ = source.with_suffix(".typ")
        if typ.is_file():
            return typ
    return source


def source_url(source: Path) -> str:
    """生成元ファイルの GitHub 上の URL。リポジトリ外なら空文字。"""
    source = source_file_for_link(source)
    try:
        relative = source.resolve().relative_to(REPO_ROOT.resolve()).as_posix()
    except ValueError:
        return ""
    return (
        f"{repository_url()}/blob/"
        f"{quote(repository_branch(), safe='/')}/"
        f"{quote(relative, safe='/')}"
    )


def replace_repository_links(html_text: str, source: Path) -> str:
    """リポジトリのトップへのリンクを、生成元ファイルの URL に置き換える。"""
    url = source_url(source)
    if not url:
        return html_text
    root = repository_url().rstrip("/").lower()

    def replace(match: re.Match[str]) -> str:
        href = match.group("href").strip()
        normalized = href.rstrip("/").lower()
        if normalized.endswith(".git"):
            normalized = normalized[: -len(".git")]
        if normalized != root:
            return match.group(0)
        return (
            f"{match.group('prefix')}{match.group('quote')}"
            f"{url}{match.group('quote')}"
        )

    return _ANCHOR_HREF_RE.sub(replace, html_text)
