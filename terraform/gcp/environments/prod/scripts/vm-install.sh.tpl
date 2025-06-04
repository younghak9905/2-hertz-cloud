#!/bin/bash
set -e

# 로그 기록
exec > >(tee -a /var/log/base-init.log) 2>&1

echo "========== 기본 초기화 시작 =========="

# deploy 사용자 생성 및 SSH 키 등록
if id "deploy" &>/dev/null; then
  echo "[INFO] deploy 사용자 이미 존재함"
else
  echo "[INFO] deploy 사용자 생성 및 SSH 키 등록"
  useradd -m -s /bin/bash deploy
  mkdir -p /home/deploy/.ssh
  echo "${deploy_ssh_public_key}" > /home/deploy/.ssh/authorized_keys
  chmod 700 /home/deploy/.ssh
  chmod 600 /home/deploy/.ssh/authorized_keys
  chown -R deploy:deploy /home/deploy/.ssh
fi

# deploy 사용자에 제한 sudo 권한 부여 (docker / openvpnas 제어용)
if ! grep -q "deploy" /etc/sudoers; then
  echo "deploy ALL=(ALL) NOPASSWD: /bin/systemctl * docker, /bin/systemctl * openvpnas, /bin/service openvpnas *" >> /etc/sudoers
fi


echo "[INFO] 기본 초기화 완료"

# 로그 설정
exec > >(tee /var/log/user-data.log) 2>&1
echo "======================================================"
# Docker 설치 (공식 스크립트 사용)
echo "[INFO] Docker 설치 중..."
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
sh get-docker.sh
rm -f get-docker.sh

# deploy 사용자에 docker 그룹 권한 부여
usermod -aG docker deploy

echo "[INFO] 기본 초기화 완료"

# ───────────────────────────────────────────────
# 2. ECR 로그인 (필요 시만)
# ───────────────────────────────────────────────

USE_ECR="${use_ecr}
DOCKER_IMAGE="${docker_image}"
AWS_REGION="${aws_region}"
AWS_ACCESS_KEY_ID="{aws_access_key_id}"
AWS_SECRET_ACCESS_KEY="{aws_secret_access_key}"

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