param(
    [ValidateSet("stdio", "http", "mcpo", "remoteall")]
    [string]$mode = "stdio"
)

$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]*)\s*=\s*(.*)\s*$') {
            [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), 'Process')
        }
    }
}
$port_http = if ($env:APP_PORT)  { [int]$env:APP_PORT }  else { 8000 }
$port_rest = if ($env:MCPO_PORT) { [int]$env:MCPO_PORT } else { 8001 }

function Stop-Port($port) {
    $pids = (Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue).OwningProcess | Sort-Object -Unique
    foreach ($id in $pids) { Stop-Process -Id $id -Force -ErrorAction SilentlyContinue }
}

$scriptsDir = python -c "import sys,os; print(os.path.join(os.path.dirname(sys.executable),'Scripts'))"
$env:PATH   = "$scriptsDir;$env:PATH"
$mcpProxy   = Join-Path $scriptsDir "mcp-proxy.exe"

switch ($mode) {
    "stdio" {
        python main.py
    }
    "http" {
        Stop-Port $port_http
        python -m watchfiles "$mcpProxy --host 0.0.0.0 --port $port_http -- python main.py" .
    }
    "mcpo" {
        Stop-Port $port_rest
        python -m watchfiles "mcpo --port $port_rest -- python main.py" .
    }
    "remoteall" {
        Stop-Port $port_http
        Stop-Port $port_rest
        Start-Process $mcpProxy -ArgumentList "--host", "0.0.0.0", "--port", "$port_http", "--", "python", "main.py" -NoNewWindow
        python -m watchfiles "mcpo --port $port_rest -- python main.py" .
    }
}
