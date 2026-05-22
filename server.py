from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI
from mcp.server.streamable_http_manager import StreamableHTTPSessionManager

from registry import mcp

session_manager = StreamableHTTPSessionManager(
    app=mcp._mcp_server,
    event_store=None,
    stateless=True,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with session_manager.run():
        yield


app = FastAPI(title="My Custom MCP", lifespan=lifespan)


async def handle_mcp(scope, receive, send):
    await session_manager.handle_request(scope, receive, send)


app.mount("/mcp", app=handle_mcp)


if __name__ == "__main__":
    uvicorn.run("server:app", host="0.0.0.0", port=8000)
