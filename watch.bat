@echo off
set PORT_HTTP=8000
set PORT_REST=8001

for /f "tokens=5" %%a in ('netstat -aon ^| findstr /R ":%PORT_HTTP% "') do taskkill /F /PID %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| findstr /R ":%PORT_REST% "') do taskkill /F /PID %%a >nul 2>&1

for /f "delims=" %%i in ('python -c "import sys,os; print(os.path.join(os.path.dirname(sys.executable),\"Scripts\"))"') do set PATH=%%i;%PATH%

start /B python -m uvicorn server:app --host 0.0.0.0 --port %PORT_HTTP% --reload
python -m watchfiles "mcpo --port %PORT_REST% -- python main.py" .
