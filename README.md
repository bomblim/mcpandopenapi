# My Custom MCP Server

stdio 기반 MCP(Model Context Protocol) 서버입니다.  
`mcpo`를 통해 OpenAPI/Swagger HTTP 인터페이스를 자동으로 제공하며, 하나의 Tool 정의로 MCP와 REST 양쪽에 자동 반영됩니다.

---

## 아키텍처

```
main.py (stdio MCP)
     │
     └──▶ registry.py ──▶ MCP Tools (FastMCP)
                │
                └──▶ tool_meta.py  (설명 Single Source of Truth)
                └──▶ tools.py      (비즈니스 로직)

mcpo (HTTP 게이트웨이)
     │
     ├──▶ GET  /docs          Swagger UI
     ├──▶ GET  /openapi.json  OpenAPI 스펙
     └──▶ POST /<tool_name>   Tool 엔드포인트 (자동 생성)
```

`main.py`는 stdio MCP 서버로 실행되고, `mcpo`가 이를 감싸서 HTTP 서버로 노출합니다.  
별도의 FastAPI 라우터 없이 MCP Tool 정의만으로 OpenAPI 스펙이 자동 생성됩니다.

---

## 프로젝트 구조

```
.
├── main.py              # stdio MCP 진입점 (mcp.run())
├── registry.py          # MCP Tool 등록 (FastMCP)
├── tool_meta.py         # Tool 메타데이터 중앙 관리 (Single Source of Truth)
├── tools.py             # 비즈니스 로직 re-export
├── search.py            # 비즈니스 로직: 사내 DB 검색
├── report.py            # 비즈니스 로직: 리포트 조회
├── config.py            # 환경 변수 설정 (pydantic-settings)
├── .env.example         # 환경 변수 예시
├── install.ps1 / .sh / .bat
├── start.ps1   / .sh / .bat
└── watch.ps1   / .sh / .bat
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
APP_TITLE=My Custom MCP
APP_VERSION=1.0.0
APP_HOST=0.0.0.0
APP_PORT=8000
```

### 3. 서버 실행

**프로덕션 (일반 실행)**

```bash
# Linux/Mac
./start.sh

# Windows (PowerShell)
./start.ps1

# Windows (CMD)
start.bat
```

**개발 (파일 변경 시 자동 재시작)**

```bash
# Linux/Mac
./watch.sh

# Windows (PowerShell)
./watch.ps1

# Windows (CMD)
watch.bat
```

> 재시작 시 8000번 포트를 점유 중인 프로세스를 자동으로 종료합니다.  
> `watch` 스크립트는 `watchfiles`로 `.py` 파일 변경을 감지하여 `mcpo` + MCP 프로세스를 함께 재시작합니다.

### 4. 동작 확인

| URL | 설명 |
|-----|------|
| `http://localhost:8000/docs` | Swagger UI (mcpo 자동 생성) |
| `http://localhost:8000/openapi.json` | OpenAPI 스펙 |
| `http://localhost:8000/<tool_name>` | Tool 엔드포인트 (POST) |

---

## mcpo 설정

### mcpo란?

[mcpo](https://github.com/open-webui/mcpo)는 stdio MCP 서버를 HTTP/OpenAPI 서버로 변환해 주는 프록시입니다.  
MCP Tool이 추가되면 별도 설정 없이 HTTP 엔드포인트와 Swagger 문서가 자동으로 생성됩니다.

### 실행 구조

```bash
mcpo --port 8000 -- python main.py
#     └── HTTP 포트  └── stdio MCP 서버 실행 명령
```

`mcpo`가 `python main.py`를 자식 프로세스로 실행하고, stdin/stdout으로 MCP 프로토콜을 중계합니다.

### 주요 옵션

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `--port` | `8000` | HTTP 서버 포트 |
| `--host` | `0.0.0.0` | 바인딩 주소 |
| `--api-key` | 없음 | Bearer 토큰 인증 활성화 |
| `--allow-http` | `false` | HTTPS 없이 HTTP 허용 |

#### API Key 인증 적용 예시

```bash
mcpo --port 8000 --api-key "your-secret-key" -- python main.py
```

요청 시 헤더에 추가:
```
Authorization: Bearer your-secret-key
```

`start.ps1`에 적용하려면:

```powershell
mcpo --port $port --api-key "your-secret-key" -- python main.py
```

### Claude Desktop 연동

`claude_desktop_config.json`에 stdio MCP로 직접 등록합니다.  
이 경우 `mcpo` 없이 `main.py`를 직접 사용합니다.

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

### Open WebUI / REST 클라이언트 연동

mcpo로 실행 중일 때 HTTP 엔드포인트를 사용합니다.

```bash
curl -X POST http://localhost:8000/search_internal_db \
  -H "Content-Type: application/json" \
  -d '{"query": "Q1 매출", "department": "영업팀"}'
```

---

## Tool 개발 방법

새로운 Tool을 추가할 때는 아래 3단계를 순서대로 진행합니다.

### Step 1. `tool_meta.py` — 메타데이터 등록

Tool 설명과 인자 설명을 한 곳에서 관리합니다.  
`registry.py`의 MCP description과 `api/` 의 OpenAPI 스펙 양쪽에 자동으로 주입됩니다.

```python
# tool_meta.py
TOOL_META = {
    ...
    "my_new_tool": {
        "summary": "새 Tool 요약",
        "description": "새 Tool 상세 설명",
        "args": {
            "param1": "첫 번째 파라미터 설명",
            "param2": "두 번째 파라미터 설명",
        },
        "response_description": "응답 설명",
    },
}
```

### Step 2. 비즈니스 로직 파일 생성

`my_new_tool.py` 파일을 루트에 생성합니다.

```python
# my_new_tool.py
def my_new_tool(param1: str, param2: int = 0) -> dict:
    return {"param1": param1, "param2": param2}
```

`tools.py`에 re-export를 추가합니다.

```python
# tools.py
from search import search_internal_db
from report import get_report
from my_new_tool import my_new_tool          # 추가

__all__ = ["search_internal_db", "get_report", "my_new_tool"]
```

### Step 3. `registry.py` — MCP Tool 등록

```python
from tools import get_report, search_internal_db, my_new_tool   # 추가

@mcp.tool(description=TOOL_META["my_new_tool"]["description"])
def mcp_my_new_tool(param1: str, param2: int = 0) -> dict:
    return my_new_tool(param1, param2)
```

저장하면 `watch` 스크립트가 자동으로 서버를 재시작하고, `http://localhost:8000/docs`에서 새 Tool을 즉시 확인할 수 있습니다.
