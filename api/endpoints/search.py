from fastapi import APIRouter

from api.schemas import SearchRequest
from tool_meta import TOOL_META
from tools import search_internal_db

_m = TOOL_META["search_internal_db"]
router = APIRouter()


@router.post(
    "/search_internal_db",
    summary=_m["summary"],
    description=_m["description"],
    response_description=_m["response_description"],
)
def api_search_internal_db(req: SearchRequest) -> dict:
    return search_internal_db(req.query, req.department, req.limit)
