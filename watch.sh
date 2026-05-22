#!/bin/bash
MODE=${1:-stdio}
PORT_HTTP=8000
PORT_REST=8001

export PATH="$(python3 -c "import sys,os; print(os.path.join(os.path.dirname(sys.executable),'bin'))")":$PATH

kill_port() { lsof -ti :$1 | xargs kill -9 2>/dev/null || true; }

case $MODE in
    stdio)
        python3 main.py
        ;;
    http)
        kill_port $PORT_HTTP
        python3 -m uvicorn server:app --host 0.0.0.0 --port $PORT_HTTP --reload
        ;;
    mcpo)
        kill_port $PORT_REST
        python3 -m watchfiles "mcpo --port $PORT_REST -- python3 main.py" .
        ;;
    remoteall)
        kill_port $PORT_HTTP
        kill_port $PORT_REST
        python3 -m uvicorn server:app --host 0.0.0.0 --port $PORT_HTTP --reload &
        python3 -m watchfiles "mcpo --port $PORT_REST -- python3 main.py" .
        ;;
    *)
        echo "Usage: $0 [stdio|http|mcpo|remoteall]"
        echo "  stdio     : stdio MCP             (Claude Desktop 직접 연결)"
        echo "  http      : StreamableHTTP MCP    (:${PORT_HTTP}/mcp)"
        echo "  mcpo      : REST/OpenAPI          (:${PORT_REST}/docs)"
        echo "  remoteall : http + mcpo 동시 실행"
        exit 1
        ;;
esac
