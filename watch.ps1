$port_http = 8000
$port_rest = 8001

foreach ($port in @($port_http, $port_rest)) {
    $pids = (Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue).OwningProcess | Sort-Object -Unique
    foreach ($id in $pids) {
        Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
    }
}

$env:PATH = (python -c "import sys,os; print(os.path.join(os.path.dirname(sys.executable),'Scripts'))") + ";$env:PATH"

# StreamableHTTP MCP server with reload (:8000/mcp)
Start-Process python -ArgumentList "-m", "uvicorn", "server:app", "--host", "0.0.0.0", "--port", "$port_http", "--reload" -NoNewWindow

# mcpo REST/OpenAPI server with watchfiles (:8001)
python -m watchfiles "mcpo --port $port_rest -- python main.py" .
