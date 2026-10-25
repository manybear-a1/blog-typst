"""Typst のコンパイル。"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

from .config import REPO_ROOT
from .errors import HatenaPostError


def default_typst_root(typ_path: Path) -> Path:
    resolved = typ_path.resolve()
    try:
        resolved.relative_to(REPO_ROOT)
    except ValueError:
        return resolved.parent
    return REPO_ROOT


def compile_typ(
    typ_path: Path,
    *,
    root: Path,
    html_out: Path | None = None,
    verbose: bool = False,
) -> Path:
    """typ を html にコンパイルして、そのパスを返す。"""
    typst = shutil.which("typst")
    if typst is None:
        raise HatenaPostError(
            "typst コマンドが見つかりません。PATH を確認するか、"
            "コンパイル済みの .html を引数に渡してください。"
        )

    output = html_out or typ_path.with_suffix(".html")
    command = [
        typst,
        "compile",
        "--root",
        str(root),
        "--features",
        "html",
        "--format",
        "html",
        str(typ_path),
        str(output),
    ]
    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        raise HatenaPostError(
            "typst のコンパイルに失敗しました"
            f" (exit {result.returncode})\n"
            f"コマンド: {' '.join(command)}\n"
            f"--- typst の出力 ---\n{result.stderr.strip()}"
        )
    if not output.is_file():
        raise HatenaPostError(f"typst の出力ファイルがありません: {output}")

    if verbose and result.stderr.strip():
        print("--- typst の警告 ---")
        print(result.stderr.strip())
    return output


def warn_if_html_is_stale(html_path: Path) -> None:
    typ_path = html_path.with_suffix(".typ")
    if not typ_path.is_file():
        return
    if typ_path.stat().st_mtime > html_path.stat().st_mtime:
        print(
            f"注意: {typ_path.name} の方が新しいです。"
            ".html ではなく .typ を引数に渡すと自動でコンパイルします。",
            file=sys.stderr,
        )
