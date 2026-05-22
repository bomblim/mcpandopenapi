#!/bin/bash
PORT=8000
lsof -ti :$PORT | xargs kill -9 2>/dev/null || true
python3 -m uvicorn main:app --host 0.0.0.0 --port $PORT
