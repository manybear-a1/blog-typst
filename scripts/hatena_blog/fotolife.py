"""はてなフォトライフへの画像アップロード。"""

from __future__ import annotations

import base64
import mimetypes
import xml.etree.ElementTree as ET
from pathlib import Path
from xml.sax.saxutils import escape

from .config import DEFAULT_FOTOLIFE_ENDPOINT, FOTOLIFE_NS
from .errors import HatenaPostError
from .http_client import request


def upload_image(
    path: Path,
    hatena_id: str,
    api_key: str,
    *,
    endpoint: str = DEFAULT_FOTOLIFE_ENDPOINT,
) -> str:
    """画像をフォトライフへアップロードして、画像 URL を返す。"""
    mime = mimetypes.guess_type(path.name)[0]
    if not mime or not mime.startswith("image/"):
        raise HatenaPostError(
            f"画像としてアップロードできないファイルです: {path}（{mime or '種類不明'}）"
        )

    try:
        data = base64.b64encode(path.read_bytes()).decode("ascii")
    except OSError as error:
        raise HatenaPostError(f"画像を読めません: {path}\n{error}") from error

    payload = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<entry xmlns="http://purl.org/atom/ns#">\n'
        f"  <title>{escape(path.name)}</title>\n"
        f'  <content type="{mime}" mode="base64">{data}</content>\n'
        "</entry>\n"
    )
    _location, body = request(
        "POST",
        endpoint,
        hatena_id=hatena_id,
        api_key=api_key,
        payload=payload,
        context=f"画像 {path.name} のアップロード",
    )
    return _image_url(body, path)


def _image_url(body: str, path: Path) -> str:
    try:
        root = ET.fromstring(body)
    except ET.ParseError as error:
        raise HatenaPostError(
            f"フォトライフのレスポンスを解析できませんでした: {path}\n{error}"
        ) from error
    node = root.find(f"{{{FOTOLIFE_NS}}}imageurl")
    if node is None or not (node.text or "").strip():
        raise HatenaPostError(
            f"フォトライフのレスポンスに画像 URL がありませんでした: {path}"
        )
    return node.text.strip()
