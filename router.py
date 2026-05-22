from fastapi import APIRouter

from api.endpoints import report_router, search_router

router = APIRouter()
router.include_router(search_router)
router.include_router(report_router)
