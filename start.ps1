$port = 8000
$pids = (Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue).OwningProcess | Sort-Object -Unique
foreach ($id in $pids) {
    Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
}

python -m uvicorn main:app --host 0.0.0.0 --port $port
