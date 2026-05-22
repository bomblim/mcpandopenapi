@echo off
set MODE=%~1
if "%MODE%"=="" set MODE=stdio

set APP_PORT=8000
set MCPO_PORT=8001
if exist "%~dp0.env" (
    for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%~dp0.env") do (
        if not "%%a"=="" set %%a=%%b
    )
)
set PORT_HTTP=%APP_PORT%
set PORT_REST=%MCPO_PORT%

for /f "delims=" %%i in ('python -c "import sys,os; print(os.path.join(os.path.dirname(sys.executable),\"Scripts\"))"') do set PATH=%%i;%PATH%

if "%MODE%"=="stdio"     goto stdio
if "%MODE%"=="http"      goto http
if "%MODE%"=="mcpo"      goto mcpo
if "%MODE%"=="remoteall" goto remoteall

echo Usage: start.bat [stdio^|http^|mcpo^|remoteall]
echo   stdio     : stdio MCP             (Claude Desktop 직접 연결)
echo   http      : StreamableHTTP MCP    (:%PORT_HTTP%/mcp)
echo   mcpo      : REST/OpenAPI          (:%PORT_REST%/docs)
echo   remoteall : http + mcpo 동시 실행
goto :eof

:stdio
python main.py
goto :eof

:http
for /f "tokens=5" %%a in ('netstat -aon ^| findstr /R ":%PORT_HTTP% "') do taskkill /F /PID %%a >nul 2>&1
mcp-proxy --host 0.0.0.0 --port %PORT_HTTP% -- python main.py
goto :eof

:mcpo
for /f "tokens=5" %%a in ('netstat -aon ^| findstr /R ":%PORT_REST% "') do taskkill /F /PID %%a >nul 2>&1
mcpo --port %PORT_REST% -- python main.py
goto :eof

:remoteall
for /f "tokens=5" %%a in ('netstat -aon ^| findstr /R ":%PORT_HTTP% "') do taskkill /F /PID %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| findstr /R ":%PORT_REST% "') do taskkill /F /PID %%a >nul 2>&1
start /B mcp-proxy --host 0.0.0.0 --port %PORT_HTTP% -- python main.py
mcpo --port %PORT_REST% -- python main.py
goto :eof
