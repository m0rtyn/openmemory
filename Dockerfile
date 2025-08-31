# OpenMemory monolithic API image (without Qdrant). UI is not included here.
# Build args (optional):
#   PIP_EXTRA_INDEX_URL

FROM python:3.12-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# System deps (add curl for health checks / debugging)
RUN apt-get update && apt-get install -y --no-install-recommends build-essential curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies first (leverage layer cache)
COPY api/requirements.txt /app/api/requirements.txt
RUN pip install --no-cache-dir -r /app/api/requirements.txt

# Copy API source
COPY api /app/api
WORKDIR /app/api

# Expose runtime port ($PORT provided by Railway) fallback 8765
ENV PORT=8765

# Healthcheck (simple: try hitting docs)
HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD curl -fsS http://localhost:${PORT}/docs >/dev/null || exit 1

# Default env variable placeholders (can be overridden in Railway)
ENV OPENAI_API_KEY="" \
    USER=default_user \
    QDRANT_HOST=localhost \
    QDRANT_PORT=6333

# Start command: use $PORT from environment
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT} --workers 4"]
