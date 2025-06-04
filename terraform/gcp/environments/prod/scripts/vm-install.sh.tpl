#!/bin/bash
set -euo pipefail

# ───────────────────────────────────────────────
# Terraform 템플릿 변수
# ───────────────────────────────────────────────
DEPLOY_SSH_PUBLIC_KEY="${deploy_ssh_public_key}"
DOCKER_IMAGE="${docker_image}"
USE_ECR="${use_ecr}"
AWS_REGION="${aws_region}"
AWS_ACCESS_KEY_ID="${aws_access_key_id}"
AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"

# ───────────────────────────────────────────────
# 1. 기본 시스템 설정
# ───────────────────────────────────────────────
echo "[INFO] 시작: VM 초기화 스크립트"

# 1-1) SSH 키 설정
if [[ -n "$DEPLOY_SSH_PUBLIC_KEY" ]]; then
  echo "[INFO] SSH 공개키 설정"
  mkdir -p /home/ubuntu/.ssh
  echo "$DEPLOY_SSH_PUBLIC_KEY" >> /home/ubuntu/.ssh/authorized_keys
  chmod 600 /home/ubuntu/.ssh/authorized_keys
  chown -R ubuntu:ubuntu /home/ubuntu/.ssh
fi

# 1-2) 패키지 업데이트 및 Docker 설치
echo "[INFO] 패키지 업데이트 및 Docker 설치"
apt-get update -qq
apt-get install -y docker.io awscli jq

# Docker 서비스 시작
systemctl enable docker
systemctl start docker

# ubuntu 사용자를 docker 그룹에 추가
usermod -aG docker ubuntu

echo "[INFO] 기본 초기화 완료"

# ───────────────────────────────────────────────
# 2. ECR 로그인 (필요 시만)
# ───────────────────────────────────────────────
if [[ "$USE_ECR" == "true" ]] && [[ -n "$AWS_REGION" ]] && [[ -n "$AWS_ACCESS_KEY_ID" ]]; then
  echo "[INFO] ECR 로그인 시작"
  
  # 2-1) AWS 자격 증명 설정
  mkdir -p ~/.aws
  cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id=$AWS_ACCESS_KEY_ID
aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
EOF

  cat > ~/.aws/config <<EOF
[default]
region=$AWS_REGION
output=json
EOF

  # 2-2) 환경변수 설정
  export AWS_DEFAULT_REGION=$AWS_REGION
  export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

  # 2-3) ECR 레지스트리 추출 및 로그인
  if [[ -n "$DOCKER_IMAGE" ]]; then
    # 이미지 URL에서 레지스트리 도메인 추출
    # 예: 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
    AWS_REGISTRY=$(echo "$DOCKER_IMAGE" | cut -d'/' -f1)
    
    # AWS 계정 ID 추출
    AWS_ACCOUNT_ID=$(echo "$AWS_REGISTRY" | cut -d'.' -f1)
    
    # 리전이 레지스트리 URL에 포함되어 있는지 확인
    # ECR URL 패턴: {account}.dkr.ecr.{region}.amazonaws.com
    REGISTRY_REGION=$(echo "$AWS_REGISTRY" | grep -oP '\.ecr\.\K[^.]+(?=\.amazonaws\.com)' || echo "")
    
    if [[ -z "$REGISTRY_REGION" ]]; then
      # URL에서 리전을 찾을 수 없으면 제공된 리전 사용
      REGISTRY_REGION=$AWS_REGION
      echo "[INFO] 기본 리전 사용: $REGISTRY_REGION"
    else
      echo "[INFO] 레지스트리 리전: $REGISTRY_REGION"
    fi
    
    echo "[INFO] ECR 레지스트리: $AWS_REGISTRY"
    echo "[INFO] AWS 계정 ID: $AWS_ACCOUNT_ID"
    
    # ECR 로그인 토큰 받기
    echo "[INFO] ECR 로그인 토큰 요청 중..."
    LOGIN_TOKEN=$(aws ecr get-login-password --region "$REGISTRY_REGION" 2>&1)
    
    if [[ $? -eq 0 ]]; then
      echo "[INFO] Docker 로그인 시도 중..."
      echo "$LOGIN_TOKEN" | docker login --username AWS --password-stdin "$AWS_REGISTRY"
      
      if [[ $? -eq 0 ]]; then
        echo "[SUCCESS] ECR 로그인 성공"
      else
        echo "[ERROR] Docker 로그인 실패"
        exit 1
      fi
    else
      echo "[ERROR] ECR 로그인 토큰 획득 실패: $LOGIN_TOKEN"
      exit 1
    fi
  else
    echo "[WARNING] Docker 이미지가 지정되지 않음"
  fi
else
  echo "[INFO] ECR 사용 안 함 또는 필수 정보 누락"
  echo "[INFO] USE_ECR: $USE_ECR"
  echo "[INFO] AWS_REGION: $AWS_REGION"
  echo "[INFO] AWS_ACCESS_KEY_ID 설정됨: $([ -n "$AWS_ACCESS_KEY_ID" ] && echo "Yes" || echo "No")"
fi