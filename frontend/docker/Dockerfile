# 1단계: Build 단계
FROM node:20-alpine AS builder
RUN npm install -g pnpm
WORKDIR /app

# 종속성 설치용 사전 복사
COPY pnpm-lock.yaml ./
COPY package.json ./
RUN pnpm install

# 전체 코드 복사 및 빌드
COPY . .
RUN pnpm build

# 2단계: 실행용 이미지
FROM node:20-alpine
RUN npm install -g pnpm
WORKDIR /app

# 빌드된 결과 복사
COPY --from=builder /app ./

EXPOSE 3000
CMD ["pnpm", "start"]