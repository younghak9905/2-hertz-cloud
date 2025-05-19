#!/bin/bash

set -e

echo "🚀 [AI 서버 배포 시작] $(date)"

### ✅ 설정
APP_NAME_AI="fastapi-ai"
APP_DIR="/home/deploy/2-hertz-ai"
GIT_BRANCH="develop"
VENV_DIR="/home/deploy/venv"
ENV="${ENV:-dev}"

# 커밋 해시 관련
COMMIT_DIR="/home/deploy/commit-hashes"
CURRENT_COMMIT_FILE="$COMMIT_DIR/ai-current-commit.txt"
DEPLOYED_COMMIT_FILE="$COMMIT_DIR/ai-deployed-commit.txt"

# 디렉토리 준비
mkdir -p "$COMMIT_DIR"
cd "$APP_DIR"
git config --global --add safe.directory "$APP_DIR"

# 롤백 분기
if [ "$1" == "--rollback" ]; then
  if [ -f "$DEPLOYED_COMMIT_FILE" ]; then
    ROLLBACK_COMMIT=$(cat "$DEPLOYED_COMMIT_FILE")
    echo "🔙 롤백 실행: $ROLLBACK_COMMIT"
    git switch --detach "$ROLLBACK_COMMIT" || {
      echo "❌ git switch 실패"
      exit 1
    }
  else
    echo "❌ 롤백 실패: $DEPLOYED_COMMIT_FILE 없음"
    exit 1
  fi
else
  echo "📦 최신 코드 pull"
  git fetch origin
  git checkout "$GIT_BRANCH"
  #git pull origin "$GIT_BRANCH" || exit 1
  git reset --hard "origin/$GIT_BRANCH"  # 로컬 브랜치를 원격 상태로 강제 초기화
fi

# 현재 커밋 해시 저장
CURRENT_COMMIT=$(git rev-parse HEAD)
echo "$CURRENT_COMMIT" > "$CURRENT_COMMIT_FILE"
echo "📌 현재 커밋 기록됨: $CURRENT_COMMIT"

### 🐍 가상환경 확인 및 활성화
echo "🐍 가상환경 확인 및 활성화..."
if [ ! -d "$VENV_DIR" ]; then
  echo "가상환경이 존재하지 않음, 생성 중..."
  python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

if [[ -z "$VIRTUAL_ENV" ]]; then
  echo "❌ 가상환경 활성화 실패"
  exit 1
fi

echo "✅ 가상환경 활성화 완료: $VIRTUAL_ENV"

pip install -r requirements.txt || echo "📦 requirements.txt 없음, 건너뜀"

### ♻️ PM2 재시작
if pm2 describe "$APP_NAME_AI" > /dev/null; then
  echo "♻️ PM2 프로세스 재시작 중..."
  pm2 restart /home/deploy/ecosystem.config.js --only "$APP_NAME_AI" || exit 1
else
  echo "🚀 PM2 프로세스 새로 시작..."
  pm2 start /home/deploy/ecosystem.config.js --only "$APP_NAME_AI" || exit 1
fi

### 배포 성공 시 커밋 저장
if [ "$1" != "--rollback" ]; then
  echo "$CURRENT_COMMIT" > "$DEPLOYED_COMMIT_FILE"
  echo "📝 배포 성공 커밋 저장됨: $CURRENT_COMMIT"
fi

echo "✅ AI 서버 배포 완료!"