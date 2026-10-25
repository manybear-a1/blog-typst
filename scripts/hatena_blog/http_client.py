"""HTTP リクエストの薄いラッパー（WSSE 認証つき）。"""

from __future__ import annotations

import urllib.error
import urllib.request

from .auth import build_wsse_header
from .errors import HatenaPostError

USER_AGENT = "blog-typst-hatena-poster/2.0"


def request(
    method: str,
    url: str,
    *,
    hatena_id: str,
    api_key: str,
    payload: str | None = None,
    context: str = "リクエスト",
    not_found_hint: str = "",
) -> tuple[str, str]:
    """(Location ヘッダ, レスポンス本文) を返す。"""
    http_request = urllib.request.Request(
        url,
        data=payload.encode("utf-8") if payload is not None else None,
        method=method,
        headers={
            "Content-Type": "application/atom+xml; charset=utf-8",
            "Accept": "application/atom+xml",
            "X-WSSE": build_wsse_header(hatena_id, api_key),
            "User-Agent": USER_AGENT,
        },
    )
    try:
        with urllib.request.urlopen(http_request, timeout=60) as response:
            body = response.read().decode("utf-8", "replace")
            return response.headers.get("Location", ""), body
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", "replace")
        hint = ""
        if not_found_hint and error.code in (404, 410):
            hint = f"\nヒント: {not_found_hint}"
        raise HatenaPostError(
            f"{context}に失敗しました: HTTP {error.code} {error.reason}\n"
            f"URL: {url}{hint}\n"
            f"--- レスポンス ---\n{body[:2000]}"
        ) from error
    except urllib.error.URLError as error:
        raise HatenaPostError(f"接続に失敗しました: {error.reason}") from error
