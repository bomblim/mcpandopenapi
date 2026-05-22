#!/bin/bash
PORT_HTTP=8000
PORT_REST=8001

lsof -ti :$PORT_HTTP | xargs kill -9 2>/dev/null || true
lsof -ti :$PORT_REST | xargs kill -9 2>/dev/null || true

export PATH="$(python3 -c "import sys,os; print(os.path.join(os.path.dirname(sys.executable),'bin'))")":$PATH

# StreamableHTTP MCP server (:8000/mcp)
python3 -m uvicorn server:app --host 0.0.0.0 --port $PORT_HTTP &

# mcpo REST/OpenAPI server (:8001)
mcpo --port $PORT_REST -- python3 main.py
