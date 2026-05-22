from typing import Optional

from mcp.server.fastmcp import FastMCP

from tool_meta import TOOL_META
from tools import get_report, search_internal_db

mcp = FastMCP("my-custom-mcp")


@mcp.tool(description=TOOL_META["search_internal_db"]["description"])
def mcp_search_internal_db(
    query: str,                        # 필수
    department: Optional[str] = None,  # 선택
    limit: int = 10,                   # 선택
) -> dict:
    return search_internal_db(query, department, limit)


@mcp.tool(description=TOOL_META["get_report"]["description"])
def mcp_get_report(
    report_id: str,                    # 필수
    include_charts: bool = False,      # 선택
) -> dict:
    return get_report(report_id, include_charts)
