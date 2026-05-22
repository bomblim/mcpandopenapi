from typing import Optional

from pydantic import BaseModel, Field

from tool_meta import TOOL_META

_s = TOOL_META["search_internal_db"]["args"]
_r = TOOL_META["get_report"]["args"]


class SearchRequest(BaseModel):
    query:      str           = Field(...,  description=_s["query"])
    department: Optional[str] = Field(None, description=_s["department"])
    limit:      int           = Field(10,   description=_s["limit"], ge=1, le=100)


class ReportRequest(BaseModel):
    report_id:      str  = Field(...,   description=_r["report_id"])
    include_charts: bool = Field(False, description=_r["include_charts"])
