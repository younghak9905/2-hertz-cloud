# ==================== 베이스 스테이지 ====================
FROM node:20-alpine AS base
WORKDIR /app

# pnpm 설치 (공식 방법)
RUN corepack enable && corepack prepare pnpm@8.15.5 --activate

# ==================== 의존성 스테이지 ====================
FROM base AS deps
COPY pnpm-lock.yaml package.json ./
RUN pnpm install --frozen-lockfile

# ==================== 빌드 스테이지 ====================
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# 빌드 시점 환경변수
ARG NEXT_PUBLIC_API_BASE_URL
ARG NEXT_PUBLIC_WS_URL

# 빌드 및 프로덕션 의존성만 유지
RUN pnpm run build && pnpm prune --prod

# ==================== 프로덕션 스테이지 ====================
FROM base AS production

# pnpm 재설치 (base에서만 깔렸으므로)
RUN corepack enable && corepack prepare pnpm@8.15.5 --activate

COPY --from=builder /app/package.json ./
COPY --from=builder /app/pnpm-lock.yaml ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.mjs ./

ENV NODE_ENV=production

EXPOSE 3000

CMD ["pnpm", "start"]