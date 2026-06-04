FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV APP_HOST=0.0.0.0
ENV APP_PORT=8000
ENV MCPO_PORT=8001

# 사용할 포트를 노출 (실행 모드에 맞게 선택)
EXPOSE ${APP_PORT}
#EXPOSE ${MCPO_PORT}

# ─────────────────────────────────────────────
# 실행 모드 선택 — 아래 CMD 중 하나만 활성화
# ─────────────────────────────────────────────

# [1] StreamableHTTP transport — http://localhost:8000/mcp
CMD ["mcp", "run", "registry.py", "--transport", "streamable-http", "--port", "8000"]

# [2] mcpo — REST/OpenAPI 래퍼, http://localhost:8001/docs
# CMD ["mcpo", "--port", "8001", "--", "python", "main.py"]

# [3] mcp-proxy — SSE 브릿지, http://localhost:8000
# CMD ["mcp-proxy", "--port", "8000", "python", "main.py"]
