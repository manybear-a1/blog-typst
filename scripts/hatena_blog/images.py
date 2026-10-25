"""記事中の画像をフォトライフへアップロードし、URL を差し替える。"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

from .config import DEFAULT_FOTOLIFE_ENDPOINT
from .errors import HatenaPostError
from .fotolife import upload_image
from .html_extract import (
    find_image_sources,
    is_remote_source,
    resolve_image_path,
)


@dataclass
class ImageUpdate:
    """1 枚の画像について何をしたか。"""

    src: str
    status: str  # reused / uploaded / planned
    url: str = ""
    path: Path | None = None


@dataclass
class ImageResult:
    mapping: dict[str, str] = field(default_factory=dict)
    updates: list[ImageUpdate] = field(default_factory=list)
    uploaded: bool = False


def _sha1(path: Path) -> str:
    digest = hashlib.sha1()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def process_images(
    content: str,
    *,
    base_dir: Path,
    root: Path,
    records: dict,
    hatena_id: str | None = None,
    api_key: str | None = None,
    endpoint: str = DEFAULT_FOTOLIFE_ENDPOINT,
    dry_run: bool = False,
) -> ImageResult:
    """content 中の画像を処理し、src → URL の対応を返す。

    records は状態ファイルの ``images`` をそのまま渡す（アップロードした
    画像の情報を追記する）。``dry_run`` ではアップロードせず、予定だけ返す。
    """
    result = ImageResult()
    for src in find_image_sources(content):
        if is_remote_source(src):
            continue

        path = resolve_image_path(src, base_dir=base_dir, root=root)
        if not path.is_file():
            raise HatenaPostError(
                f"画像が見つかりません: {src}\n  探した場所: {path}"
            )

        digest = _sha1(path)
        record = records.get(src) if isinstance(records.get(src), dict) else None
        if record and record.get("sha1") == digest and record.get("url"):
            result.mapping[src] = record["url"]
            result.updates.append(
                ImageUpdate(src, "reused", record["url"], path)
            )
            continue

        if dry_run:
            if record and record.get("url"):
                result.mapping[src] = record["url"]
            result.updates.append(ImageUpdate(src, "planned", "", path))
            continue

        if hatena_id is None or api_key is None:
            raise HatenaPostError(
                f"画像 {src} をアップロードするには API キーが必要です。"
            )
        url = upload_image(path, hatena_id, api_key, endpoint=endpoint)
        records[src] = {
            "url": url,
            "sha1": digest,
            "uploaded": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        }
        result.mapping[src] = url
        result.updates.append(ImageUpdate(src, "uploaded", url, path))
        result.uploaded = True

    return result
