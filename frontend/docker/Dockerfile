# 1단계: Build 단계
FROM node:20-alpine AS builder
RUN npm install -g pnpm
WORKDIR /app

# 종속성 설치만을 위한 레이어 캐시
COPY pnpm-lock.yaml package.json ./
RUN pnpm install

# 소스 복사 (이때까지 캐시 최대한 활용)
COPY . .

# 🔥 환경변수는 여기서 주입 (캐시가 깨져도 최소 영향)
ARG NEXT_PUBLIC_API_BASE_URL
ENV NEXT_PUBLIC_API_BASE_URL=${NEXT_PUBLIC_API_BASE_URL}

RUN pnpm build

# 2단계: 실행용 이미지
FROM node:20-alpine
RUN npm install -g pnpm
WORKDIR /app

# 빌드된 결과 복사
COPY --from=builder /app ./

EXPOSE 3000
CMD ["pnpm", "start"]