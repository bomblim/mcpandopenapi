# My Custom MCP Server

MCP(Model Context Protocol) 서버로, 세 가지 전송 방식을 지원합니다.

- **stdio** (`main.py`): Claude Desktop 직접 연결, MCP Inspector
- **StreamableHTTP** (`mcp-proxy`): MCP 클라이언트가 HTTP로 연결
- **REST/OpenAPI** (`mcpo`): Swagger UI, HTTP REST 클라이언트

---

## 아키텍처

```
                    ┌─ registry.py ─┐
                    │  MCP Tools    │◀── tool_meta.py (tools/tool_meta.jsonc)
                    │  (FastMCP)    │◀── tools/ (비즈니스 로직)
                    └──────┬────────┘
                           │
                       main.py (stdio)
                           │
          ┌────────────────┼─────────────────┐
          │                │                 │
     직접 실행          mcp-proxy          mcpo
   (stdio transport)   :APP_PORT          :MCPO_PORT
          │                │                 │
   Claude Desktop      /mcp endpoint      /docs
   MCP Inspector       MCP 클라이언트     /openapi.json
                                          /<tool_name>
```

---

## 프로젝트 구조

```
.
├── main.py              # stdio MCP 진입점 (mcp.run())
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

# StreamableHTTP MCP 서버 포트 — mcp-proxy (http://localhost:8000/mcp)
APP_PORT=8000

# REST/OpenAPI 서버 포트 — mcpo (http://localhost:8001/docs)
MCPO_PORT=8001
```

> 포트 값은 `start` / `watch` 스크립트 실행 시 `.env`에서 자동으로 읽어옵니다.  
> `.env`가 없으면 기본값(`APP_PORT=8000`, `MCPO_PORT=8001`)을 사용합니다.

### 3. 서버 실행

모드 인자로 실행 방식을 선택합니다. 인자가 없으면 기본값 `stdio`로 실행됩니다.

| 모드 | 설명 | 포트 |
|------|------|------|
| `stdio` | stdio MCP (기본값) | — |
| `http` | StreamableHTTP MCP via mcp-proxy | `APP_PORT` |
| `mcpo` | REST/OpenAPI via mcpo | `MCPO_PORT` |
| `remoteall` | http + mcpo 동시 실행 | `APP_PORT` + `MCPO_PORT` |

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

> `watch` 모드 재시작 동작:
> - `http`: mcp-proxy를 `watchfiles`로 감지하여 자동 재시작
> - `mcpo`: mcpo를 `watchfiles`로 감지하여 자동 재시작
> - `remoteall`: mcpo만 `watchfiles` 자동 재시작 / mcp-proxy는 백그라운드 직접 실행(재시작 필요 시 스크립트 재실행)
>
> 재시작 시 해당 포트를 점유 중인 프로세스를 자동으로 종료합니다.

### 4. 동작 확인

| URL | 모드 | 설명 |
|-----|------|------|
| `http://localhost:8000/mcp` | `http` | MCP StreamableHTTP 엔드포인트 |
| `http://localhost:8001/docs` | `mcpo` | Swagger UI |
| `http://localhost:8001/openapi.json` | `mcpo` | OpenAPI 스펙 |
| `http://localhost:8001/<tool_name>` | `mcpo` | Tool REST 엔드포인트 (POST) |

### 5. MCP Inspector

```powershell
./inspect.ps1
```

브라우저에서 `http://localhost:6274`로 접속하여 Tool을 테스트할 수 있습니다.

---

## 클라이언트 연동

### Claude Desktop — stdio

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

`start.ps1 -mode http` 실행 후 HTTP 방식으로 연결합니다.

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

`start.ps1 -mode mcpo` 실행 후 REST 엔드포인트를 사용합니다.

```bash
curl -X POST http://localhost:8001/search_internal_db \
  -H "Content-Type: application/json" \
  -d '{"query": "Q1 매출", "department": "영업팀"}'
```

---

## mcpo / mcp-proxy 설정

### mcpo — REST/OpenAPI 게이트웨이

[mcpo](https://github.com/open-webui/mcpo)는 stdio MCP를 HTTP/OpenAPI 서버로 변환합니다.

```bash
mcpo --port 8001 -- python main.py
```

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `--port` | `8000` | HTTP 서버 포트 |
| `--host` | `0.0.0.0` | 바인딩 주소 |
| `--api-key` | 없음 | Bearer 토큰 인증 |
| `--allow-http` | `false` | HTTPS 없이 HTTP 허용 |

API Key 인증 적용:
```bash
mcpo --port 8001 --api-key "your-secret-key" -- python main.py
# 요청 헤더: Authorization: Bearer your-secret-key
```

### mcp-proxy — SSE/StreamableHTTP 게이트웨이

[mcp-proxy](https://github.com/sparfenyuk/mcp-proxy)는 stdio MCP를 SSE 또는 StreamableHTTP 서버로 변환합니다.

```bash
mcp-proxy --host 0.0.0.0 --port 8000 -- python main.py
```

> 기본 host가 `127.0.0.1`이므로 외부 접근이 필요한 경우 반드시 `--host 0.0.0.0`을 지정해야 합니다.

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `--port` | 랜덤 | 노출할 포트 |
| `--host` | `127.0.0.1` | 바인딩 주소 |
| `--allow-origin` | 없음 | CORS 허용 origin |
| `--stateless` | `false` | Stateless 모드 (StreamableHTTP) |

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
