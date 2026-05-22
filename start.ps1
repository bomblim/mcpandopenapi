param(
    [ValidateSet("stdio", "http", "mcpo", "remoteall")]
    [string]$mode = "stdio"
)

$port_http = 8000
$port_rest = 8001

function Stop-Port($port) {
    $pids = (Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue).OwningProcess | Sort-Object -Unique
    foreach ($id in $pids) { Stop-Process -Id $id -Force -ErrorAction SilentlyContinue }
}

$env:PATH = (python -c "import sys,os; print(os.path.join(os.path.dirname(sys.executable),'Scripts'))") + ";$env:PATH"

switch ($mode) {
    "stdio" {
        python main.py
    }
    "http" {
        Stop-Port $port_http
        python -m uvicorn server:app --host 0.0.0.0 --port $port_http
    }
    "mcpo" {
        Stop-Port $port_rest
        mcpo --port $port_rest -- python main.py
    }
    "remoteall" {
        Stop-Port $port_http
        Stop-Port $port_rest
        Start-Process python -ArgumentList "-m", "uvicorn", "server:app", "--host", "0.0.0.0", "--port", "$port_http" -NoNewWindow
        mcpo --port $port_rest -- python main.py
    }
}
