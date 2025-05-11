#!/bin/bash

APP_DIR="/home/ec2-user/app"
cd "$APP_DIR" || exit 1

CONTAINER_NAME="nextjs-frontend"
ENV_FILE="$APP_DIR/.env"

# .env 파일 확인
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ .env 파일이 존재하지 않습니다. 배포 중단."
  exit 1
fi

# 안전한 환경변수 로딩
set -a
. "$ENV_FILE"
set +a

# 필수 환경변수 확인
if [[ -z "$AWS_ACCOUNT_ID" || -z "$AWS_REGION" || -z "$IMAGE_TAG" ]]; then
  echo "❌ 필수 환경변수(AWS_ACCOUNT_ID, AWS_REGION, IMAGE_TAG)가 누락되었습니다."
  exit 1
fi

IMAGE_NAME="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/hertz-fe:$IMAGE_TAG"

# ECR 로그인
echo "🔐 ECR 로그인 중..."
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# 이미지 Pull
echo "📥 Docker 이미지 Pull: $IMAGE_NAME"
docker pull "$IMAGE_NAME"

# 기존 컨테이너 중지 및 제거
echo "🛑 기존 컨테이너 종료 및 삭제: $CONTAINER_NAME"
docker stop "$CONTAINER_NAME" || true
docker rm "$CONTAINER_NAME" || true

# 새 컨테이너 실행
echo "🚀 새 컨테이너 실행 중..."
docker run -d \
  --name "$CONTAINER_NAME" \
  -p 3000:3000 \
  --restart always \
  --memory="1.5g" \
  --cpus="1.5" \
  "$IMAGE_NAME"

# 컨테이너 상태 확인
echo "📋 실행 중인 컨테이너 상태"
docker ps --filter "name=$CONTAINER_NAME"

# 실행 확인
if ! docker ps | grep -q "$CONTAINER_NAME"; then
  echo "❌ 컨테이너 실행 실패"
  exit 1
fi

echo "✅ 컨테이너 실행 성공"
exit 0