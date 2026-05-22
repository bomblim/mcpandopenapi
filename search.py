from typing import Optional


def search_internal_db(
    query: str,
    department: Optional[str] = None,
    limit: int = 10,
) -> dict:
    """사내 DB 검색 비즈니스 로직"""
    # 실제 DB 로직으로 교체
    return {
        "total": 2,
        "results": [
            {"id": 1, "title": f"{query} 관련 문서 1", "dept": department},
            {"id": 2, "title": f"{query} 관련 문서 2", "dept": department},
        ],
    }
