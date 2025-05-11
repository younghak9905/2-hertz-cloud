# ==================== 베이스 스테이지 ====================
FROM node:20-alpine AS base
WORKDIR /app

# ==================== 의존성 스테이지 ====================
FROM base AS deps
COPY package*.json ./
RUN npm ci

# ==================== 빌드 스테이지 ====================
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# 빌드 시점 환경변수
ARG NEXT_PUBLIC_API_BASE_URL
ARG NEXT_PUBLIC_WS_URL
# 빌드 및 프로덕션 의존성만 유지
RUN npm run build && npm prune --production

# ==================== 프로덕션 스테이지 ====================
FROM base AS production

# 필요한 파일들 복사
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.mjs ./

# 환경변수 설정
ENV NODE_ENV=production

# 포트 노출
EXPOSE 3000

# 실행
CMD ["npm", "start"]