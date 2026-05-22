# My Custom MCP Server

MCP(Model Context Protocol) 서버로, 두 가지 전송 방식을 병행 운영합니다.

- **StreamableHTTP** (`server.py`): MCP 클라이언트가 HTTP로 직접 연결
- **stdio + mcpo** (`main.py`): REST/OpenAPI 자동 생성, Claude Desktop stdio 연결, MCP Inspector

---

## 아키텍처

```
                    ┌─ registry.py ─┐
                    │  MCP Tools    │◀── tool_meta.py (tools/tool_meta.jsonc)
                    │  (FastMCP)    │◀── tools/ (비즈니스 로직)
                    └──────┬────────┘
                           │
          ┌────────────────┴─────────────────┐
          │                                  │
    server.py                            main.py
  (StreamableHTTP)                        (stdio)
          │                                  │
    uvicorn :8000                        mcpo :8001
          │                                  │
    GET/POST /mcp    ──  MCP 클라이언트    GET  /docs
                                         GET  /openapi.json
                                         POST /<tool_name>
```

---

## 프로젝트 구조

```
.
├── main.py              # stdio MCP 진입점 (mcp.run())
├── server.py            # StreamableHTTP MCP 진입점 (FastAPI + /mcp)
├── registry.py          # MCP Tool 등록 (FastMCP)
├── tool_meta.py         # tool_meta.jsonc 로더
├── tools/
│   ├── __init__.py      # 비즈니스 로직 re-export
│   ├── search.py        # 사내 DB 검색 구현
│   ├── report.py        # 리포트 조회 구현
│   └── tool_meta.jsonc  # Tool 메타데이터 (Single Source of Truth)
├── .env.example
├── install.ps1 / .sh / .bat
├── start.ps1   / .sh / .bat
├── watch.ps1   / .sh / .bat
└── inspect.ps1
```

---

## Quick Start

### 1. 의존성 설치

```bash
# Linux/Mac
./install.sh

# Windows (PowerShell)
./install.ps1

# Windows (CMD)
install.bat
```

### 2. 환경 변수 설정 (선택)

`.env.example`을 복사하여 `.env`를 생성한 뒤 필요한 값을 수정합니다.

```bash
# Linux/Mac
cp .env.example .env

# Windows
copy .env.example .env
```

```env
APP_HOST=0.0.0.0

# StreamableHTTP MCP 서버 포트 (http://localhost:8000/mcp)
APP_PORT=8000

# mcpo REST/OpenAPI 서버 포트 (http://localhost:8001/docs)
MCPO_PORT=8001
```

### 3. 서버 실행

`start` / `watch` 스크립트는 모드 인자로 실행 방식을 선택합니다.  
인자가 없으면 기본값 `stdio`로 실행됩니다.

| 모드 | 설명 | 포트 |
|------|------|------|
| `stdio` | stdio MCP (기본값) | — |
| `http` | StreamableHTTP MCP | `:8000/mcp` |
| `mcpo` | REST/OpenAPI | `:8001/docs` |
| `remoteall` | http + mcpo 동시 실행 | `:8000` + `:8001` |

**프로덕션 (일반 실행)**

```bash
# Linux/Mac
./start.sh [stdio|http|mcpo|remoteall]

# Windows (PowerShell)
./start.ps1 [-mode stdio|http|mcpo|remoteall]

# Windows (CMD)
start.bat [stdio|http|mcpo|remoteall]
```

**개발 (파일 변경 시 자동 재시작)**

```bash
# Linux/Mac
./watch.sh [stdio|http|mcpo|remoteall]

# Windows (PowerShell)
./watch.ps1 [-mode stdio|http|mcpo|remoteall]

# Windows (CMD)
watch.bat [stdio|http|mcpo|remoteall]
```

> `watch` 모드: `http`는 uvicorn `--reload`, `mcpo`·`remoteall`은 `watchfiles`로 파일 변경을 감지합니다.  
> 재시작 시 해당 모드의 포트를 점유 중인 프로세스를 자동으로 종료합니다.

### 4. 동작 확인

| URL | 서버 | 설명 |
|-----|------|------|
| `http://localhost:8000/mcp` | server.py (uvicorn) | MCP StreamableHTTP 엔드포인트 |
| `http://localhost:8001/docs` | main.py (mcpo) | Swagger UI |
| `http://localhost:8001/openapi.json` | main.py (mcpo) | OpenAPI 스펙 |
| `http://localhost:8001/<tool_name>` | main.py (mcpo) | Tool REST 엔드포인트 (POST) |

### 5. MCP Inspector

```powershell
./inspect.ps1
```

브라우저에서 `http://localhost:6274`로 접속하여 Tool을 테스트할 수 있습니다.

---

## 클라이언트 연동

### Claude Desktop — stdio

`claude_desktop_config.json`에 stdio MCP로 등록합니다.

```json
{
  "mcpServers": {
    "my-custom-mcp": {
      "command": "python",
      "args": ["C:/path/to/project/main.py"]
    }
  }
}
```

### Claude Desktop — StreamableHTTP

서버 실행 후 HTTP 방식으로 연결합니다.

```json
{
  "mcpServers": {
    "my-custom-mcp": {
      "type": "http",
      "url": "http://localhost:8000/mcp"
    }
  }
}
```

### Open WebUI / REST 클라이언트

mcpo가 제공하는 REST 엔드포인트를 사용합니다.

```bash
curl -X POST http://localhost:8001/search_internal_db \
  -H "Content-Type: application/json" \
  -d '{"query": "Q1 매출", "department": "영업팀"}'
```

---

## mcpo 설정

[mcpo](https://github.com/open-webui/mcpo)는 stdio MCP 서버를 HTTP/OpenAPI 서버로 변환해 주는 프록시입니다.

### 실행 구조

```bash
mcpo --port 8001 -- python main.py
#     └── HTTP 포트   └── stdio MCP 서버 실행 명령
```

### 주요 옵션

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `--port` | `8000` | HTTP 서버 포트 |
| `--host` | `0.0.0.0` | 바인딩 주소 |
| `--api-key` | 없음 | Bearer 토큰 인증 활성화 |
| `--allow-http` | `false` | HTTPS 없이 HTTP 허용 |

### API Key 인증

```bash
mcpo --port 8001 --api-key "your-secret-key" -- python main.py
```

요청 시 헤더:
```
Authorization: Bearer your-secret-key
```

---

## Tool 개발 방법

새로운 Tool을 추가할 때는 아래 3단계를 순서대로 진행합니다.

### Step 1. `tools/tool_meta.jsonc` — 메타데이터 등록

```jsonc
{
    "my_new_tool": {
        "summary": "새 Tool 요약",
        "description": "새 Tool 상세 설명",
        "args": {
            "param1": "첫 번째 파라미터 설명",
            "param2": "두 번째 파라미터 설명"
        },
        "response_description": "응답 설명"
    }
}
```

### Step 2. `tools/my_new_tool.py` — 비즈니스 로직 구현

```python
def my_new_tool(param1: str, param2: int = 0) -> dict:
    return {"param1": param1, "param2": param2}
```

`tools/__init__.py`에 re-export 추가:

```python
from .search import search_internal_db
from .report import get_report
from .my_new_tool import my_new_tool  # ← 추가

__all__ = ["search_internal_db", "get_report", "my_new_tool"]  # ← my_new_tool 추가
```

### Step 3. `registry.py` — MCP Tool 등록

기존 import 라인에 `my_new_tool`을 추가하고, `@mcp.tool` 블록을 append합니다.

```python
# 기존 라인에 my_new_tool 추가
from tools import get_report, search_internal_db, my_new_tool

# 아래 블록 전체 추가
@mcp.tool(description=TOOL_META["my_new_tool"]["description"])
def mcp_my_new_tool(param1: str, param2: int = 0) -> dict:
    return my_new_tool(param1, param2)
```

저장하면 `watch` 스크립트가 자동으로 재시작하고, `http://localhost:8001/docs`에서 새 Tool을 즉시 확인할 수 있습니다.
