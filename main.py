from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI
from mcp.server.streamable_http_manager import StreamableHTTPSessionManager

from api import router
from config import settings
from registry import mcp


# ── Session Manager ───────────────────────────────────────────────────────────
session_manager = StreamableHTTPSessionManager(
    app=mcp._mcp_server,
    event_store=None,
    stateless=True,
)


# ── Lifespan (task group 초기화) ──────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    async with session_manager.run():
        yield


# ── FastAPI App ───────────────────────────────────────────────────────────────
app = FastAPI(
    title=settings.app_title,
    version=settings.app_version,
    lifespan=lifespan,
)

# REST 엔드포인트 등록 (/openapi.json 자동 생성)
app.include_router(router)


# ── MCP Streamable HTTP 엔드포인트 ────────────────────────────────────────────
async def handle_mcp(scope, receive, send):
    await session_manager.handle_request(scope, receive, send)

app.mount("/mcp", app=handle_mcp)


# ── 실행 ──────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.app_host,
        port=settings.app_port,
        reload=True,  # 개발 시 자동 reload
    )
