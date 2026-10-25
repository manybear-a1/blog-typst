"""コマンドラインインターフェース。"""

from __future__ import annotations

import argparse
import os
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

from .atom import (
    build_entry_xml,
    collection_url,
    content_format,
    list_entries,
    response_content_type,
    response_link,
    send_entry,
)
from .auth import load_api_key
from .config import (
    DEFAULT_ENDPOINT,
    DEFAULT_FOTOLIFE_ENDPOINT,
    DEFAULT_HATENA_ID,
    KEY_FILE_NAME,
    STATE_SUFFIX,
)
from .errors import HatenaPostError
from .html_extract import ExtractedArticle, extract_article, replace_image_sources
from .images import ImageResult, process_images
from .markdown_compat import to_markdown_safe
from .state import load_state, save_state, state_path_for, take_legacy_entry
from .typst import compile_typ, default_typst_root, warn_if_html_is_stale

DESCRIPTION = """\
Typst の記事を はてなブログへ下書き投稿・更新する。

.typ を渡すと typst compile で HTML を書き出してから投稿する。
記事ごとの <記事名>.hatena.json にエントリ URI と画像 URI を記録し、
2 回目以降は同じ記事を更新する。別記事にしたいときは --new。
"""

EPILOG = """\
例:
  python scripts/post_to_hatena.py articles/2026/anki-cloze/anki-cloze2.typ \\
      --title "記事タイトル"

  python scripts/post_to_hatena.py --list
"""


def _parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=DESCRIPTION,
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "source",
        type=Path,
        nargs="?",
        help="投稿する .typ または .html（.typ なら自動でコンパイルする）",
    )
    parser.add_argument(
        "--title",
        default=None,
        help="記事タイトル（省略時は前回のタイトル、それも無ければファイル名）",
    )
    parser.add_argument(
        "--endpoint",
        default=DEFAULT_ENDPOINT,
        help=f"AtomPub のエンドポイント（既定: {DEFAULT_ENDPOINT}）",
    )
    parser.add_argument(
        "--hatena-id",
        default=DEFAULT_HATENA_ID,
        help=f"はてな ID（既定: {DEFAULT_HATENA_ID}）",
    )
    parser.add_argument(
        "--key-file",
        default=None,
        help=f"API キーを書いたファイル（既定: 環境変数 → {KEY_FILE_NAME}）",
    )
    parser.add_argument(
        "--entry-url",
        default=None,
        help="更新する記事のメンバURI（手動で作った下書きを引き継ぐときに使う）",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="投稿せずに、最近のエントリ（最大 7 件）とメンバURIを表示する",
    )
    parser.add_argument(
        "--new",
        action="store_true",
        help="記録を無視して、新しい記事として投稿する",
    )
    parser.add_argument(
        "--publish",
        action="store_true",
        help="下書きではなく公開記事として投稿する",
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=None,
        help="typst の --root（既定: リポジトリ直下）",
    )
    parser.add_argument(
        "--html-out",
        type=Path,
        default=None,
        help="typst の HTML 出力先（既定: .typ と同じ場所の同名 .html）",
    )
    parser.add_argument(
        "--state-file",
        type=Path,
        default=None,
        help=f"状態ファイルの保存先（既定: <記事名>{STATE_SUFFIX}）",
    )
    parser.add_argument(
        "--fotolife-endpoint",
        default=DEFAULT_FOTOLIFE_ENDPOINT,
        help=f"フォトライフの投稿先（既定: {DEFAULT_FOTOLIFE_ENDPOINT}）",
    )
    parser.add_argument(
        "--skip-images",
        action="store_true",
        help="画像をアップロードせず、src をそのまま送る",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="投稿せず、送信する XML を書き出して内容を確認する",
    )
    parser.add_argument(
        "--payload-out",
        type=Path,
        default=None,
        help="--dry-run 時に XML を保存するパス（省略時は一時ファイル）",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="typst の警告なども表示する",
    )
    return parser.parse_args(argv)


def _html_path(source: Path, args: argparse.Namespace) -> Path:
    suffix = source.suffix.lower()
    if suffix == ".typ":
        html_path = compile_typ(
            source,
            root=args.root or default_typst_root(source),
            html_out=args.html_out,
            verbose=args.verbose,
        )
        print(f"コンパイル: {source} → {html_path}")
        return html_path
    if suffix in {".html", ".htm"}:
        warn_if_html_is_stale(source)
        return source
    raise HatenaPostError(
        f"対応していない拡張子です: {source.suffix}（.typ か .html を渡してください）"
    )


def _render(
    article: ExtractedArticle,
    fmt: str,
    image_mapping: dict[str, str],
) -> str:
    html = replace_image_sources(article.to_html(), image_mapping)
    if fmt == "markdown":
        html = to_markdown_safe(html)
    return html


def _print_images(result: ImageResult) -> None:
    labels = {
        "reused": "再利用",
        "uploaded": "アップロード",
        "planned": "アップロード予定",
    }
    for update in result.updates:
        suffix = f" {update.url}" if update.url else ""
        print(f"画像: {update.src} → {labels.get(update.status, update.status)}{suffix}")


def _run_list(args: argparse.Namespace) -> int:
    api_key, key_source = load_api_key(args.key_file)
    print(f"API キー: {key_source} から読み込み")
    entries = list_entries(args.endpoint, args.hatena_id, api_key)
    if not entries:
        print("エントリが見つかりませんでした。")
        return 0
    print(f"最近のエントリ {len(entries)} 件:")
    for entry in entries:
        state_label = "下書き" if entry["draft"] == "yes" else "公開"
        print(f"- [{state_label}] {entry['title']}")
        print(f"  {entry['updated']}  {entry['content_type']}")
        print(f"  {entry['edit_url']}")
    print()
    print("既存の記事を更新対象にするには、上のメンバURIを --entry-url に渡してください。")
    return 0


def main(argv: list[str] | None = None) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    args = _parse_args(argv)

    if args.list:
        try:
            return _run_list(args)
        except HatenaPostError as error:
            print(f"エラー: {error}", file=sys.stderr)
            return 1

    if args.source is None:
        print("エラー: 投稿する .typ / .html ファイルを指定してください。", file=sys.stderr)
        return 2
    if args.entry_url and args.new:
        print("エラー: --entry-url と --new は同時に指定できません。", file=sys.stderr)
        return 2

    source: Path = args.source
    if not source.is_file():
        print(f"エラー: ファイルが見つかりません: {source}", file=sys.stderr)
        return 2

    try:
        return _post(source, args)
    except HatenaPostError as error:
        print(f"エラー: {error}", file=sys.stderr)
        return 1


def _post(source: Path, args: argparse.Namespace) -> int:
    html_path = _html_path(source, args)

    state_file = args.state_file or state_path_for(source)
    state = load_state(state_file)
    if args.state_file is None and not state.get("entry_url"):
        migrated = take_legacy_entry(source)
        if migrated:
            state = {**migrated, **state}
            # 旧ファイルからは既に削除済みなので、先に新しいファイルへ書いておく。
            try:
                save_state(state_file, state)
            except OSError as error:
                print(
                    f"警告: 状態ファイルを保存できませんでした: {error}",
                    file=sys.stderr,
                )
            else:
                print(
                    "旧形式の .hatena-entries.json から記録を引き継ぎました: "
                    f"{state_file}"
                )

    article = extract_article(html_path.read_text(encoding="utf-8-sig"))
    title = args.title or state.get("title") or source.stem
    target = None if args.new else (args.entry_url or state.get("entry_url"))
    fmt = state.get("content_format") or "html"

    records = state.get("images")
    if not isinstance(records, dict):
        records = {}
        state["images"] = records

    image_result = ImageResult()
    if not args.skip_images and args.dry_run:
        image_result = process_images(
            article.to_html(),
            base_dir=source.parent,
            root=args.root or default_typst_root(source),
            records=records,
            endpoint=args.fotolife_endpoint,
            dry_run=True,
        )
    if "<embed" in article.to_html():
        print(
            "注意: <embed>（PDF など）はフォトライフにアップロードできません。"
            "そのまま送信します。",
            file=sys.stderr,
        )

    content = _render(article, fmt, image_result.mapping)
    method = "PUT" if target else "POST"
    send_url = target or collection_url(args.endpoint)

    print(f"入力: {source}")
    print(f"タイトル: {title}")
    if args.title is None and state.get("title"):
        print("  （前回の投稿からタイトルを引き継いでいます）")
    elif args.title is None:
        print("  （--title が未指定なのでファイル名を使用しています）")
    print(
        f"本文: {len(content):,} 文字 / "
        f"style {len(article.styles)} 個 / "
        f"脚注 {'あり' if article.endnotes else 'なし'}"
    )
    _print_images(image_result)
    print(f"記法: {fmt}（応答を確認して必要なら自動で切り替えます）")
    print(f"操作: {'更新 (PUT)' if method == 'PUT' else '新規投稿 (POST)'}")
    print(f"送信先: {send_url}")
    if target:
        print("  （同じ記事を更新します。別記事にしたいときは --new）")
    print(f"状態: {'公開' if args.publish else '下書き'}")

    if args.dry_run:
        payload = build_entry_xml(
            title, content, draft=not args.publish, author=args.hatena_id
        )
        out_path = args.payload_out
        if out_path is None:
            handle, name = tempfile.mkstemp(prefix="hatena-entry-", suffix=".xml")
            os.close(handle)
            out_path = Path(name)
        out_path.write_text(payload, encoding="utf-8")
        print(f"--dry-run のため送信しませんでした。送信 XML: {out_path}")
        return 0

    api_key, key_source = load_api_key(args.key_file)
    print(f"API キー: {key_source} から読み込み")

    if not args.skip_images:
        image_result = process_images(
            article.to_html(),
            base_dir=source.parent,
            root=args.root or default_typst_root(source),
            records=records,
            endpoint=args.fotolife_endpoint,
            hatena_id=args.hatena_id,
            api_key=api_key,
        )
        _print_images(image_result)
        if image_result.uploaded:
            save_state(state_file, state)

    content = _render(article, fmt, image_result.mapping)
    payload = build_entry_xml(
        title, content, draft=not args.publish, author=args.hatena_id
    )
    created = method == "POST"
    location, body = send_entry(method, send_url, args.hatena_id, api_key, payload)
    entry_location = target or location

    actual = content_format(response_content_type(body))
    if actual and actual != fmt and actual in {"html", "markdown"} and entry_location:
        print(
            f"このブログは {actual} で保存されるため、"
            f"{actual} 向けに変換して再送信します。"
        )
        fmt = actual
        content = _render(article, fmt, image_result.mapping)
        payload = build_entry_xml(
            title, content, draft=not args.publish, author=args.hatena_id
        )
        location, body = send_entry(
            "PUT", entry_location, args.hatena_id, api_key, payload
        )
        method = "PUT"
        actual = content_format(response_content_type(body)) or actual

    if actual:
        fmt = actual

    entry_url = entry_location or location
    if entry_url:
        state.update(
            {
                "entry_url": entry_url,
                "title": title,
                "content_format": fmt,
                "updated": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            }
        )
        try:
            save_state(state_file, state)
        except OSError as error:
            print(f"警告: 状態ファイルを保存できませんでした: {error}", file=sys.stderr)
        else:
            print(f"記録: {state_file}（次回はこの記事を更新します）")
    else:
        print(
            "警告: レスポンスに Location ヘッダが無いため、記事の URL を記録できませんでした。"
            "次回も新規投稿になるので、--entry-url で指定してください。",
            file=sys.stderr,
        )

    print(f"{'投稿' if created else '更新'}しました: {entry_url or send_url}")
    alternate = response_link(body, "alternate")
    if alternate and alternate != entry_url:
        print(f"記事 URL: {alternate}")
    return 0
