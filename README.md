# My Custom MCP Server

FastAPI 기반의 MCP(Model Context Protocol) + OpenAPI 서버입니다.  
REST API와 MCP 엔드포인트를 동시에 제공하며, 하나의 Tool 정의로 양쪽에 자동 반영됩니다.

---

## 프로젝트 구조

```
.
├── main.py              # FastAPI 앱 진입점, MCP 마운트
├── config.py            # 환경 변수 설정 (pydantic-settings)
├── registry.py          # MCP Tool 등록
├── tool_meta.py         # Tool 메타데이터 중앙 관리 (Single Source of Truth)
├── search.py            # 비즈니스 로직: 사내 DB 검색
├── report.py            # 비즈니스 로직: 리포트 조회
├── tools.py             # 비즈니스 로직 re-export
├── api/
│   ├── __init__.py
│   ├── router.py        # APIRouter 조합
│   ├── schemas.py       # Pydantic Request 모델
│   └── endpoints/
│       ├── search.py    # POST /search_internal_db
│       └── report.py    # POST /get_report
└── mnt/                 # 참조용 초기 설계 파일 (무시 가능)
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

### 4. 동작 확인

| URL | 설명 |
|-----|------|
| `http://localhost:8000/docs` | Swagger UI (REST API) |
| `http://localhost:8000/openapi.json` | OpenAPI 스펙 |
| `http://localhost:8000/mcp` | MCP Streamable HTTP 엔드포인트 |

---

## Tool 개발 방법

새로운 Tool을 추가할 때는 아래 4단계를 순서대로 진행합니다.

### Step 1. `tool_meta.py` — 메타데이터 등록

Tool 설명, 인자 설명, 응답 설명을 한 곳에서 관리합니다.  
MCP description과 OpenAPI summary/description 양쪽에 자동으로 주입됩니다.

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
    # 실제 로직 구현
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

### Step 3. `api/` — REST 엔드포인트 추가

**Request 스키마** (`api/schemas.py`)

```python
class MyNewToolRequest(BaseModel):
    param1: str       = Field(...,  description=TOOL_META["my_new_tool"]["args"]["param1"])
    param2: int       = Field(0,    description=TOOL_META["my_new_tool"]["args"]["param2"])
```

**엔드포인트** (`api/endpoints/my_new_tool.py`)

```python
from fastapi import APIRouter
from api.schemas import MyNewToolRequest
from tool_meta import TOOL_META
from tools import my_new_tool

_m = TOOL_META["my_new_tool"]
router = APIRouter()

@router.post(
    "/my_new_tool",
    summary=_m["summary"],
    description=_m["description"],
    response_description=_m["response_description"],
)
def api_my_new_tool(req: MyNewToolRequest) -> dict:
    return my_new_tool(req.param1, req.param2)
```

**라우터에 등록** (`api/endpoints/__init__.py`)

```python
from .report import router as report_router
from .search import router as search_router
from .my_new_tool import router as my_new_tool_router   # 추가

__all__ = ["search_router", "report_router", "my_new_tool_router"]
```

`api/router.py`에서 포함시킵니다.

```python
from api.endpoints import report_router, search_router, my_new_tool_router

router = APIRouter()
router.include_router(search_router)
router.include_router(report_router)
router.include_router(my_new_tool_router)   # 추가
```

### Step 4. `registry.py` — MCP Tool 등록

```python
from tools import get_report, search_internal_db, my_new_tool

@mcp.tool(description=TOOL_META["my_new_tool"]["description"])
def mcp_my_new_tool(param1: str, param2: int = 0) -> dict:
    return my_new_tool(param1, param2)
```

---

## 아키텍처 요약

```
tool_meta.py  ←─────────────────────────────┐
     │                                       │
     ▼                                       │
비즈니스 로직 (search.py, report.py, ...)    │
     │                                       │
     ├──▶ api/endpoints/*.py  ──▶ REST API  (OpenAPI/Swagger)
     │
     └──▶ registry.py  ──▶ MCP Tools  (/mcp)
```

`tool_meta.py`가 Single Source of Truth로, 하나의 설명을 수정하면 REST API 문서와 MCP Tool 설명이 동시에 반영됩니다.
