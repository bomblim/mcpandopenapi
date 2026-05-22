from fastapi import APIRouter

from api.schemas import ReportRequest
from tool_meta import TOOL_META
from tools import get_report

_m = TOOL_META["get_report"]
router = APIRouter()


@router.post(
    "/get_report",
    summary=_m["summary"],
    description=_m["description"],
    response_description=_m["response_description"],
)
def api_get_report(req: ReportRequest) -> dict:
    return get_report(req.report_id, req.include_charts)
