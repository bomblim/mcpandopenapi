import json
import re
from pathlib import Path


def _load_jsonc(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    text = re.sub(r"//[^\n]*", "", text)
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    return json.loads(text)


TOOL_META = _load_jsonc(Path(__file__).parent / "tools" / "tool_meta.jsonc")
