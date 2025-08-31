# syntax=docker.io/docker/dockerfile:1

# Base stage for common setup
FROM node:20-alpine AS base

# Install dependencies for pnpm
RUN apk add --no-cache libc6-compat curl && \
    corepack enable && \
    corepack prepare pnpm@latest --activate

WORKDIR /app

FROM base AS deps
COPY package.json pnpm-lock.yaml ./
# Install all deps (will be pruned later)
RUN pnpm install --frozen-lockfile

FROM base AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/pnpm-lock.yaml ./pnpm-lock.yaml
COPY . .

ARG NEXT_PUBLIC_API_URL="http://localhost:8765"
ARG NEXT_PUBLIC_USER_ID="user"
ARG FORCE_REBUILD=0  # change or pass --build-arg to bust cache
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL \
    NEXT_PUBLIC_USER_ID=$NEXT_PUBLIC_USER_ID

RUN if [ -f .env.example ]; then cp .env.example .env; fi \
 && echo "NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL" >> .env \
 && echo "NEXT_PUBLIC_USER_ID=$NEXT_PUBLIC_USER_ID" >> .env \
 && echo "Building standalone at $(date -u) (force=$FORCE_REBUILD)" \
 && pnpm build

FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Fallback: if standalone build missing, install prod deps and start with next directly
RUN if [ ! -f server.js ]; then echo "[warn] Standalone output missing; installing prod deps"; pnpm install --prod --frozen-lockfile || true; fi

COPY --chown=nextjs:nodejs entrypoint.sh /home/nextjs/entrypoint.sh
RUN chmod +x /home/nextjs/entrypoint.sh

USER nextjs

EXPOSE 3000
ENV PORT=3000 \
    HOSTNAME="0.0.0.0"

HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD wget -q -O - http://127.0.0.1:3000/ >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/home/nextjs/entrypoint.sh"]
CMD ["sh", "-c", "if [ -f server.js ]; then echo 'Starting standalone server.js'; exec node server.js; else echo 'Starting next start (no standalone)'; exec pnpm start; fi"]
