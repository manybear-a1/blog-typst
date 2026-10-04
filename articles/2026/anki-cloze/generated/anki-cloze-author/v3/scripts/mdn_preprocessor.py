"""Normalize MDN-specific Markdown before generic Markdown conversion.

The generic generator imports ``normalize_mdn_markdown`` so that MDN rules do
not leak into the reusable Markdown-to-HTML implementation. For another
documentation dialect, replace or add a separate preprocessor instead.
"""

import re
from html import escape


LIVE_SAMPLE_FENCE_RE = re.compile(
    r"^```(?P<language>[A-Za-z0-9_-]+)(?: (?:hidden )?live-sample[^\n]*)?$",
    re.MULTILINE,
)
LIVE_SAMPLE_BLOCK_RE = re.compile(
    r"^```(?P<language>[A-Za-z0-9_-]+) (?P<hidden>hidden )?live-sample[^\n]*\n"
    r"(?P<code>.*?)^```\s*$",
    re.MULTILINE | re.DOTALL,
)
HTML_CODE_FENCE_RE = re.compile(
    r"^```html\n(?P<code>.*?)^```\s*$",
    re.MULTILINE | re.DOTALL,
)
MDN_MACRO_RE = re.compile(
    r"^\{\{\s*(?:EmbedLiveSample|NextMenu)\(.*?\)\s*\}\}\s*$",
    re.MULTILINE,
)


def normalize_mdn_markdown(text, render_samples=True):
    """Normalize MDN syntax, optionally rendering complete HTML samples."""
    text = re.sub(r"\\([<>])", lambda match: {"<": "&lt;", ">": "&gt;"}[match.group(1)], text)
    if render_samples:
        text = LIVE_SAMPLE_BLOCK_RE.sub(render_live_sample, text)
        text = HTML_CODE_FENCE_RE.sub(render_html_code, text)
    text = LIVE_SAMPLE_FENCE_RE.sub(r"```\g<language>", text)
    return MDN_MACRO_RE.sub("", text)


def render_live_sample(match):
    """Turn an MDN live-sample fence into code plus a rendered result."""
    language = match.group("language")
    code = match.group("code").strip("\n")
    return render_code_and_result(language, code)


def render_html_code(match):
    """Turn a regular HTML fence into code plus a rendered result."""
    return render_code_and_result("html", match.group("code").strip("\n"))


def render_code_and_result(language, code):
    """Return HTML that shows escaped source and renders the original code."""
    escaped_code = escape(code, quote=False)
    return (
        '<div class="mdn-code-example">'
        f'<pre><code class="language-{language}">{escaped_code}</code></pre>'
        '<hr>'
        f'<div class="mdn-rendered-result">{code}</div>'
        '<hr>'
        "</div>"
    )
