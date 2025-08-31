#!/usr/bin/env bash
set -euo pipefail

echo "[run_api] Working directory: $(pwd)"
# Ensure we are in repository root (script lives there). Then cd into api.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/api"

echo "[run_api] Installing/ensuring dependencies (idempotent)"
# In case build layer missed something or Railway pruned caches
pip install --no-cache-dir -r requirements.txt

export PYTHONUNBUFFERED=1
PORT="${PORT:-8000}"

echo "[run_api] Launching uvicorn on port $PORT"
exec uvicorn main:app --host 0.0.0.0 --port "$PORT"
