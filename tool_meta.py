# Single Source of Truth: 모든 Tool 설명 중앙 관리
# MCP tool description + FastAPI OpenAPI 스펙 양쪽에 주입됨

TOOL_META = {
    "search_internal_db": {
        "summary": "사내 DB 검색",
        "description": (
            "사내 데이터베이스에서 키워드 또는 자연어로 데이터를 검색합니다.\n"
            "- 특정 부서만 검색하려면 department를 지정하세요.\n"
            "- 결과는 최신순으로 반환됩니다.\n"
            "- 검색 결과가 없으면 빈 리스트를 반환합니다."
        ),
        "args": {
            "query":      "검색할 키워드 또는 자연어 질문. 예: 'Q1 매출 현황', '신규 고객 수'",
            "department": "검색 범위를 특정 부서로 제한. 미입력 시 전사 검색. 예: '영업팀'",
            "limit":      "반환할 최대 결과 수. 기본값 10, 최대 100",
        },
        "response_description": "검색 결과 목록과 총 건수",
    },
    "get_report": {
        "summary": "리포트 조회",
        "description": (
            "리포트 ID로 사내 리포트를 조회합니다.\n"
            "- report_id는 /list_reports 로 목록 조회 후 사용하세요.\n"
            "- 존재하지 않는 ID 입력 시 404를 반환합니다."
        ),
        "args": {
            "report_id":      "조회할 리포트 고유 ID. 예: 'RPT-2024-001'",
            "include_charts": "차트 데이터 포함 여부. True 시 응답 용량이 커짐",
        },
        "response_description": "리포트 상세 내용 및 메타데이터",
    },
}
