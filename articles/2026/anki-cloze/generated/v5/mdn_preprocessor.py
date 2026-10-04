import re


LIVE_SAMPLE_FENCE_RE = re.compile(
    r"^```(?P<language>[A-Za-z0-9_-]+)(?: (?:hidden )?live-sample[^\n]*)?$",
    re.MULTILINE,
)
MDN_MACRO_RE = re.compile(
    r"^\{\{\s*(?:EmbedLiveSample|NextMenu)\(.*?\)\s*\}\}\s*$",
    re.MULTILINE,
)


def normalize_mdn_markdown(text):
    """Convert MDN-specific Markdown conventions to regular Markdown."""
    text = re.sub(r"\\([<>])", lambda match: {"<": "&lt;", ">": "&gt;"}[match.group(1)], text)
    text = LIVE_SAMPLE_FENCE_RE.sub(r"```\g<language>", text)
    return MDN_MACRO_RE.sub("", text)
