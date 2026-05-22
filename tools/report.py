def get_report(report_id: str, include_charts: bool = False) -> dict:
    """리포트 조회 비즈니스 로직"""
    # 실제 DB 로직으로 교체
    return {
        "report_id":  report_id,
        "title":      "2024 Q1 매출 리포트",
        "content":    "리포트 내용...",
        "chart_data": {"labels": [], "values": []} if include_charts else None,
    }
