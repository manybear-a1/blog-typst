"""既定値とパス。"""

from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]

DEFAULT_ENDPOINT = "https://blog.hatena.ne.jp/manybear/manybear.hatenablog.com/atom"
DEFAULT_HATENA_ID = "manybear"
DEFAULT_FOTOLIFE_ENDPOINT = "https://f.hatena.ne.jp/atom/post"
DEFAULT_REPOSITORY_URL = "https://github.com/manybear-a1/blog-typst"
DEFAULT_REPOSITORY_BRANCH = "main"

KEY_FILE_NAME = ".hatena-api-key"
LEGACY_STATE_FILE_NAME = ".hatena-entries.json"
STATE_SUFFIX = ".hatena.json"

ATOM_NS = "http://www.w3.org/2005/Atom"
APP_NS = "http://www.w3.org/2007/app"
FOTOLIFE_NS = "http://www.hatena.ne.jp/info/xmlns#"

# はてなブログの content type → 内部での呼び名
CONTENT_FORMATS = {
    "text/html": "html",
    "text/x-markdown": "markdown",
    "text/x-hatena-syntax": "hatena",
}
