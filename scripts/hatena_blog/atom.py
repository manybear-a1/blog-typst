"""はてなブログ AtomPub API。"""

from __future__ import annotations

import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from xml.sax.saxutils import escape

from .config import APP_NS, ATOM_NS, CONTENT_FORMATS
from .errors import HatenaPostError
from .http_client import request


def build_entry_xml(
    title: str,
    content: str,
    *,
    draft: bool = True,
    author: str | None = None,
    updated: datetime | None = None,
) -> str:
    timestamp = (updated or datetime.now(timezone.utc)).strftime("%Y-%m-%dT%H:%M:%SZ")
    draft_value = "yes" if draft else "no"
    author_xml = f"  <author><name>{escape(author)}</name></author>\n" if author else ""
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<entry xmlns="{ATOM_NS}" xmlns:app="{APP_NS}">\n'
        f"  <title>{escape(title)}</title>\n"
        f'  <content type="text/html">{_cdata(content)}</content>\n'
        f"  <updated>{timestamp}</updated>\n"
        f"{author_xml}"
        "  <app:control>\n"
        f"    <app:draft>{draft_value}</app:draft>\n"
        "  </app:control>\n"
        "</entry>\n"
    )


def _cdata(text: str) -> str:
    return "<![CDATA[" + text.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def collection_url(endpoint: str) -> str:
    return endpoint.rstrip("/") + "/entry"


def send_entry(
    method: str,
    url: str,
    hatena_id: str,
    api_key: str,
    payload: str,
) -> tuple[str, str]:
    """POST / PUT して (Location ヘッダ, レスポンス本文) を返す。"""
    return request(
        method,
        url,
        hatena_id=hatena_id,
        api_key=api_key,
        payload=payload,
        context="更新" if method == "PUT" else "投稿",
        not_found_hint=(
            "更新先の記事が見つかりません。記事を削除した場合は --new で新規投稿するか、"
            "--entry-url で正しいメンバURIを指定してください。"
        ),
    )


def list_entries(endpoint: str, hatena_id: str, api_key: str) -> list[dict[str, str]]:
    """最近のエントリ（最大 7 件）を取得する。"""
    _location, body = request(
        "GET",
        collection_url(endpoint),
        hatena_id=hatena_id,
        api_key=api_key,
        context="一覧の取得",
    )
    try:
        root = ET.fromstring(body)
    except ET.ParseError as error:
        raise HatenaPostError(f"一覧の XML を解析できませんでした: {error}") from error

    entries: list[dict[str, str]] = []
    for entry in root.findall(f"{{{ATOM_NS}}}entry"):
        edit_url = ""
        for link in entry.findall(f"{{{ATOM_NS}}}link"):
            if link.get("rel") == "edit":
                edit_url = link.get("href", "")
        draft = entry.find(f"{{{APP_NS}}}control/{{{APP_NS}}}draft")
        content = entry.find(f"{{{ATOM_NS}}}content")
        entries.append(
            {
                "title": (entry.findtext(f"{{{ATOM_NS}}}title") or "").strip(),
                "updated": (entry.findtext(f"{{{ATOM_NS}}}updated") or "").strip(),
                "edit_url": edit_url,
                "draft": (draft.text or "").strip() if draft is not None else "",
                "content_type": content.get("type", "") if content is not None else "",
            }
        )
    return entries


def response_link(body: str, rel: str) -> str:
    try:
        root = ET.fromstring(body)
    except ET.ParseError:
        return ""
    for link in root.findall(f"{{{ATOM_NS}}}link"):
        if link.get("rel") == rel and link.get("href"):
            return link.get("href", "")
    return ""


def response_content_type(body: str) -> str:
    try:
        root = ET.fromstring(body)
    except ET.ParseError:
        return ""
    content = root.find(f"{{{ATOM_NS}}}content")
    return content.get("type", "") if content is not None else ""


def content_format(content_type: str) -> str:
    """content type を html / markdown / hatena / "" に正規化する。"""
    return CONTENT_FORMATS.get(content_type.strip().lower(), "")
