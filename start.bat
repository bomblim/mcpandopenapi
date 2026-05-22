@echo off
set PORT=8000
for /f "tokens=5" %%a in ('netstat -aon ^| findstr /R ":%PORT% "') do (
    taskkill /F /PID %%a >nul 2>&1
)
python -m uvicorn main:app --host 0.0.0.0 --port %PORT%
