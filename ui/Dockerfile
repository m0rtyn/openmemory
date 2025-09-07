# Simple single-stage image keeping node_modules (next binary available)
FROM node:20-alpine

WORKDIR /app
RUN apk add --no-cache libc6-compat curl bash && npm install -g pnpm@10.5.2

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

ARG NEXT_PUBLIC_API_URL
ARG NEXT_PUBLIC_USER_ID
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL} \
    NEXT_PUBLIC_USER_ID=${NEXT_PUBLIC_USER_ID}

RUN if [ -f .env.example ]; then cp .env.example .env; fi && \
    pnpm build && \
    ls -1 .next/standalone || (echo 'standalone output missing'; exit 1) && \
    # Flatten standalone output to the app root so server.js resolves .next/static correctly
    cp -R .next/standalone/* ./

EXPOSE 3000
ENV PORT=3000 HOSTNAME="0.0.0.0"

HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD curl -fsS http://127.0.0.1:3000/ >/dev/null || exit 1

CMD ["node", "server.js"]
