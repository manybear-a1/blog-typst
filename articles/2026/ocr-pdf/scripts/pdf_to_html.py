"""Datalab API で PDF を HTML に変換するスクリプト。

使い方:
    python scripts/pdf_to_html.py decks/linear_algebra/text_linear_algebra.pdf
    python scripts/pdf_to_html.py input.pdf -o out/document.html --mode accurate

API キーはコードに埋め込まず、プロジェクトルートの `.env`
（または `--env-file` で指定したファイル / 環境変数）から読み込む。

    DATALAB_API_KEY=...
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
from pathlib import Path
from typing import Any

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ENV_FILE = PROJECT_ROOT / ".env"
API_KEY_ENV = "DATALAB_API_KEY"
HTML_SUFFIXES = {".html", ".htm"}

# MathJax v4。CDN でなくローカルに置く場合は importmap 側で差し替えられるよう、
# スクリプト側の URL は上書き可能にしておく。
MATHJAX_VERSION = "4"
MATHJAX_CDN = "https://cdn.jsdelivr.net/npm/mathjax@4"
MATHJAX_PACKAGES = "tex-chtml"

MATHJAX_CONFIG = """<script>
window.MathJax = {
  tex: {
    inlineMath: [['\\\\(', '\\\\)']],
    displayMath: [['\\\\[', '\\\\]']],
  },
  chtml: { scale: 1 },
};
</script>
<script id="MathJax-script" src="%s/%s.js"></script>
"""

# <math> … </math> の内側をそのまま MathJax に渡す。内側は HTML エスケープ済み
# （& → &amp;、< → &lt;、> → &gt;）のまま出力するので、ここでは一切デコードしない。
MATH_TAG_PATTERN = re.compile(
    r"<math(?:\s[^>]*)?>(.*?)</math\s*>",
    re.IGNORECASE | re.DOTALL,
)


class ConfigError(Exception):
    """API キーや入力ファイルなど、実行前の設定の問題。"""


def read_env_file(path: Path) -> dict[str, str]:
    """`.env` を読み、空でない値だけを返す。"""
    try:
        from dotenv import dotenv_values
    except ImportError:
        return _parse_env_text(path.read_text(encoding="utf-8-sig"))
    return {key: value for key, value in dotenv_values(path).items() if value is not None}


def _parse_env_text(text: str) -> dict[str, str]:
    """python-dotenv が無い環境向けの最小限の .env パーサ。"""
    values: dict[str, str] = {}
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[len("export ") :].strip()
        name, separator, value = line.partition("=")
        if not separator:
            continue
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        values[name.strip()] = value
    return values


def load_api_key(env_file: Path | None = None) -> str:
    """環境変数 → 指定 .env → プロジェクトルート/.env → cwd/.env の順でキーを解決する。"""
    if env_file is not None:
        if not env_file.is_file():
            raise ConfigError(f"env ファイルが見つかりません: {env_file}")
        candidates = [env_file]
    else:
        candidates = [
            path for path in (DEFAULT_ENV_FILE, Path.cwd() / ".env") if path.is_file()
        ]

    for path in candidates:
        for name, value in read_env_file(path).items():
            os.environ.setdefault(name, value)

    api_key = os.environ.get(API_KEY_ENV, "").strip()
    if not api_key:
        location = candidates[0] if candidates else DEFAULT_ENV_FILE
        raise ConfigError(
            f"{API_KEY_ENV} が設定されていません。{location} に "
            f"{API_KEY_ENV}=... を書くか、環境変数として設定してください。"
        )
    return api_key


def resolve_output_path(pdf_path: Path, output: str | None) -> Path:
    """出力先を決める。既定は PDF と同じディレクトリの `<stem>.html`。"""
    if output is None:
        return pdf_path.with_suffix(".html")

    path = Path(output).expanduser()
    if path.is_dir():
        return path / f"{pdf_path.stem}.html"
    if path.suffix.lower() not in HTML_SUFFIXES:
        path = path.with_suffix(".html")
    return path


def images_dir_for(output_path: Path) -> Path:
    return output_path.with_name(f"{output_path.stem}_images")


def rewrite_image_sources(html: str, filenames: list[str], relative_dir: str) -> str:
    """HTML 内の画像 src を、実際に保存したディレクトリからの相対パスに置き換える。"""
    mapping: dict[str, str] = {}
    for name in filenames:
        saved = f"{relative_dir}/{Path(name).name}"
        mapping[name] = saved
        mapping[f"./{name}"] = saved

    def replace(match: re.Match[str]) -> str:
        prefix, quote, source = match.group(1), match.group(2), match.group(3)
        return f"{prefix}{quote}{mapping.get(source, source)}{quote}"

    return re.sub(r'(\bsrc\s*=\s*)(["\'])(.*?)\2', replace, html)


def save_images(images: dict[str, str], target_dir: Path) -> int:
    """base64 の画像を target_dir に書き出し、保存した枚数を返す。"""
    if not images:
        return 0

    target_dir.mkdir(parents=True, exist_ok=True)
    for name, data in images.items():
        target = target_dir / Path(name).name
        target.write_bytes(base64.b64decode(data))
    return len(images)


def convert_math_to_tex(html: str) -> str:
    """`<math>…</math>` の LaTeX を MathJax の区切り記法に置き換える。

    `<math display=\"block\">` → `\\[ … \\]`、通常の `<math>` → `\\( … \\)`。
    内側の LaTeX はそのまま保持する（HTML エンティティもデコードしない）。
    """

    def replace(match: re.Match[str]) -> str:
        opening = match.group(0)[: match.group(0).find(">") + 1]
        latex = match.group(1).strip()
        if 'display="block"' in opening:
            return f"\\[\n{latex}\n\\]"
        return f"\\({latex}\\)"

    return MATH_TAG_PATTERN.sub(replace, html)


def inject_mathjax(html: str) -> str:
    """数式がある場合だけ MathJax の loader を `<head>` に注入する。"""
    if r"\(" not in html and r"\[" not in html:
        return html

    script = MATHJAX_CONFIG % (MATHJAX_CDN, MATHJAX_PACKAGES)
    if re.search(r"<head\b[^>]*>", html, re.IGNORECASE):
        return re.sub(r"(<head\b[^>]*>)", r"\1\n" + script, html, count=1, flags=re.IGNORECASE)
    return script + "\n" + html


def make_math_renderable(html: str) -> str:
    """`<math>` の LaTeX を MathJax で表示できる形式に変換する。"""
    return inject_mathjax(convert_math_to_tex(html))


def convert_pdf_to_html(
    pdf_path: Path,
    output_path: Path,
    api_key: str,
    mode: str = "balanced",
    page_range: str | None = None,
    max_pages: int | None = None,
    paginate: bool = False,
    save_extracted_images: bool = True,
    skip_cache: bool = False,
    add_block_ids: bool = False,
    compact: bool = False,
    extras: str | None = None,
    max_polls: int = 300,
    poll_interval: float = 1,
) -> dict[str, Any]:
    """PDF を変換して HTML と画像を保存し、実行結果のサマリを返す。"""
    try:
        from datalab_sdk import ConvertOptions, DatalabClient
    except ImportError as exc:  # pragma: no cover - 環境依存
        raise ConfigError(
            "datalab_sdk がインストールされていません。"
            "`pip install datalab-python-sdk` を実行してください。"
        ) from exc

    options = ConvertOptions(
        output_format="html",
        mode=mode,
        page_range=page_range,
        max_pages=max_pages,
        paginate=paginate,
        skip_cache=skip_cache,
        disable_image_extraction=not save_extracted_images,
        add_block_ids=add_block_ids,
        disable_html_prettify=compact,
        extras=extras,
    )

    client = DatalabClient(api_key=api_key)
    try:
        result = client.convert(
            str(pdf_path),
            options=options,
            max_polls=max_polls,
            poll_interval=poll_interval,
        )
    except Exception as exc:  # SDK 固有の例外をまとめて CLI 向けメッセージにする
        raise RuntimeError(f"Datalab API の呼び出しに失敗しました: {exc}") from exc

    # 完了しても success=False で error が返ることがある
    if not result.success:
        raise RuntimeError(result.error or "Datalab の変換に失敗しました")
    if not result.html:
        raise RuntimeError("Datalab が HTML を返しませんでした")

    output_path.parent.mkdir(parents=True, exist_ok=True)

    image_count = 0
    html = result.html
    images_dir = images_dir_for(output_path)
    if save_extracted_images and result.images:
        image_count = save_images(result.images, images_dir)
        relative_dir = images_dir.relative_to(output_path.parent).as_posix()
        html = rewrite_image_sources(html, list(result.images), relative_dir)

    html = make_math_renderable(html)
    rendered = html.count(r"\(") + html.count(r"\[")
    output_path.write_text(html, encoding="utf-8")

    return {
        "ok": True,
        "input": str(pdf_path),
        "output": str(output_path),
        "images_dir": str(images_dir) if image_count else None,
        "image_count": image_count,
        "mode": mode,
        "page_count": result.page_count,
        "parse_quality_score": result.parse_quality_score,
        "cost_breakdown": result.cost_breakdown,
        "math_count": rendered,
    }


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Datalab API で PDF を HTML に変換します。",
    )
    parser.add_argument("pdf", type=Path, help="変換する PDF のパス")
    parser.add_argument(
        "-o",
        "--output",
        help=(
            "出力 HTML のパス（既定: <PDF名>.html）。"
            "ディレクトリを指定すると <PDF名>.html を書き出します。"
        ),
    )
    parser.add_argument(
        "--mode",
        choices=("fast", "balanced", "accurate"),
        default="balanced",
        help="処理モード（既定: balanced）",
    )
    parser.add_argument("--pages", help='ページ範囲（0 始まり、例: "0-5,10"）')
    parser.add_argument("--max-pages", type=int, help="処理する最大ページ数")
    parser.add_argument("--paginate", action="store_true", help="ページ区切りを出力に含める")
    parser.add_argument(
        "--no-images",
        action="store_true",
        help="画像を抽出・保存しない",
    )
    parser.add_argument("--skip-cache", action="store_true", help="キャッシュを使わず再変換する")
    parser.add_argument(
        "--block-ids",
        action="store_true",
        help="HTML 要素に data-block-id を付ける",
    )
    parser.add_argument(
        "--compact",
        action="store_true",
        help="整形しないコンパクトな HTML を出力する",
    )
    parser.add_argument(
        "--extras",
        help='追加機能（カンマ区切り、例: "extract_links,extract_bookmarks"）',
    )
    parser.add_argument("--max-polls", type=int, default=300, help="最大ポーリング回数（既定: 300）")
    parser.add_argument(
        "--poll-interval", type=float, default=2, help="ポーリング間隔の秒数（既定: 2）"
    )
    parser.add_argument(
        "--env-file",
        type=Path,
        help="API キーを読み込む .env のパス（既定: プロジェクトルートの .env）",
    )

    args = parser.parse_args(argv)
    if args.pages and args.max_pages:
        parser.error("--pages と --max-pages は同時に指定できません")
    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    pdf_path: Path = args.pdf.expanduser()
    if not pdf_path.is_file():
        print(f"エラー: PDF が見つかりません: {pdf_path}", file=sys.stderr)
        return 1

    try:
        api_key = load_api_key(args.env_file)
        output_path = resolve_output_path(pdf_path, args.output)
        summary = convert_pdf_to_html(
            pdf_path=pdf_path,
            output_path=output_path,
            api_key=api_key,
            mode=args.mode,
            page_range=args.pages,
            max_pages=args.max_pages,
            paginate=args.paginate,
            save_extracted_images=not args.no_images,
            skip_cache=args.skip_cache,
            add_block_ids=args.block_ids,
            compact=args.compact,
            extras=args.extras,
            max_polls=args.max_polls,
            poll_interval=args.poll_interval,
        )
    except (ConfigError, RuntimeError) as exc:
        print(f"エラー: {exc}", file=sys.stderr)
        return 1

    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
