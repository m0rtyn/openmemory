# Simple single-stage image keeping node_modules (next binary available)
FROM node:20-alpine

WORKDIR /app
RUN apk add --no-cache libc6-compat curl bash && npm install -g pnpm@10.5.2

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

ENV NEXT_PUBLIC_API_URL="http://localhost:8765" \
    NEXT_PUBLIC_USER_ID="user" \
    NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1

RUN if [ -f .env.example ]; then cp .env.example .env; fi && \
    echo "NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL" >> .env && \
    echo "NEXT_PUBLIC_USER_ID=$NEXT_PUBLIC_USER_ID" >> .env && \
    pnpm build

EXPOSE 3000
ENV PORT=3000 HOSTNAME="0.0.0.0"

HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD wget -q -O - http://127.0.0.1:3000/ >/dev/null 2>&1 || exit 1

CMD ["pnpm", "start"]
