# Simple single-stage image keeping node_modules (next binary available)
FROM node:20-alpine

WORKDIR /app
RUN apk add --no-cache libc6-compat curl bash && npm install -g pnpm@10.5.2

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    NEXT_PUBLIC_API_URL=__NEXT_PUBLIC_API_URL__ \
    NEXT_PUBLIC_USER_ID=__NEXT_PUBLIC_USER_ID__

RUN if [ -f .env.example ]; then cp .env.example .env; fi && \
    echo "(placeholders) NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL" && \
    pnpm build && \
    ls -1 .next/standalone || (echo 'standalone output missing'; exit 1)

EXPOSE 3000
ENV PORT=3000 HOSTNAME="0.0.0.0"

HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD wget -q -O - http://127.0.0.1:3000/ >/dev/null 2>&1 || exit 1

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", ".next/standalone/server.js"]
