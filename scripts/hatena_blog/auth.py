"""WSSE 認証と API キーの読み込み。"""

from __future__ import annotations

import base64
import hashlib
import os
import secrets
from datetime import datetime, timezone
from pathlib import Path

from .config import KEY_FILE_NAME, REPO_ROOT
from .errors import HatenaPostError


def build_wsse_header(hatena_id: str, api_key: str) -> str:
    """はてなの WSSE 認証ヘッダを作る。"""
    nonce = secrets.token_bytes(32)
    created = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    digest = base64.b64encode(
        hashlib.sha1(nonce + created.encode("utf-8") + api_key.encode("utf-8")).digest()
    ).decode("ascii")
    return (
        f'UsernameToken Username="{hatena_id}", '
        f'PasswordDigest="{digest}", '
        f'Nonce="{base64.b64encode(nonce).decode("ascii")}", '
        f'Created="{created}"'
    )


def _parse_key_file(path: Path) -> str:
    for raw_line in path.read_text(encoding="utf-8-sig").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            name, value = line.split("=", 1)
            if name.strip().upper() in {"HATENA_API_KEY", "API_KEY"}:
                return value.strip().strip("\"'")
            continue
        return line
    raise HatenaPostError(f"API キーが空です: {path}")


def load_api_key(key_file: str | None) -> tuple[str, str]:
    """(API キー, 読み込み元の説明) を返す。"""
    if key_file:
        path = Path(key_file).expanduser()
        if not path.is_file():
            raise HatenaPostError(f"API キーファイルが見つかりません: {path}")
        return _parse_key_file(path), str(path)

    from_env = os.environ.get("HATENA_API_KEY", "").strip()
    if from_env:
        return from_env, "環境変数 HATENA_API_KEY"

    candidates = [
        Path.cwd() / KEY_FILE_NAME,
        REPO_ROOT / KEY_FILE_NAME,
        Path.home() / KEY_FILE_NAME,
    ]
    for path in candidates:
        if path.is_file():
            return _parse_key_file(path), str(path)

    searched = "\n".join(f"  - {path}" for path in candidates)
    raise HatenaPostError(
        "API キーが見つかりません。次のいずれかを用意してください。\n"
        "  1. --key-file でファイルを指定する\n"
        "  2. 環境変数 HATENA_API_KEY を設定する\n"
        f"  3. 次の場所に {KEY_FILE_NAME} を置く（中身は API キーだけ）\n{searched}"
    )
