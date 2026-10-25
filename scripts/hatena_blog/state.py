"""記事ごとの状態ファイル（エントリ URI と画像 URI）の管理。

記事ごとに ``<記事名>.hatena.json`` を置く。以前のバージョンが使っていた
``.hatena-entries.json``（全記事を 1 ファイルで管理）があれば、その記事の
項目だけを引き継いで削除する。
"""

from __future__ import annotations

import json
import os
from pathlib import Path

from .config import LEGACY_STATE_FILE_NAME, REPO_ROOT, STATE_SUFFIX
from .errors import HatenaPostError


def state_path_for(source: Path) -> Path:
    """``foo.typ`` / ``foo.html`` → ``foo.hatena.json``。"""
    return source.with_name(source.stem + STATE_SUFFIX)


def load_state(path: Path) -> dict:
    if not path.is_file():
        return {}
    return _read_json(path)


def save_state(path: Path, state: dict) -> None:
    """書き込み途中で壊れないよう、一時ファイル経由で保存する。"""
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(
        json.dumps(state, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    os.replace(temporary, path)


def _read_json(path: Path) -> dict:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise HatenaPostError(f"状態ファイルを読めません: {path}\n{error}") from error
    if not isinstance(data, dict):
        raise HatenaPostError(f"状態ファイルの形式が不正です: {path}")
    return data


def _legacy_key(source: Path) -> str:
    resolved = source.resolve()
    try:
        relative = resolved.relative_to(REPO_ROOT)
    except ValueError:
        return resolved.with_suffix("").as_posix()
    return relative.with_suffix("").as_posix()


def take_legacy_entry(source: Path) -> dict:
    """旧形式の記録から、この記事の項目だけ取り出して削除する。"""
    path = REPO_ROOT / LEGACY_STATE_FILE_NAME
    if not path.is_file():
        return {}
    try:
        data = _read_json(path)
    except HatenaPostError:
        return {}
    entry = data.pop(_legacy_key(source), None)
    if not isinstance(entry, dict) or not entry:
        return {}

    try:
        if data:
            save_state(path, data)
        else:
            path.unlink()
    except OSError:
        pass

    migrated: dict = {}
    if entry.get("entry_url"):
        migrated["entry_url"] = entry["entry_url"]
    if entry.get("title"):
        migrated["title"] = entry["title"]
    return migrated
