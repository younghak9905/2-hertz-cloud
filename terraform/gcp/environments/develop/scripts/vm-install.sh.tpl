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

# AWS CLI 설치 (ECR 로그인용)
echo "[INFO] AWS CLI 설치 중..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

echo "[INFO] Docker 및 AWS CLI 설치 완료"

# ───────────────────────────────────────────────
# ECR 로그인 및 Docker 이미지 처리
# ───────────────────────────────────────────────

%{ if use_ecr == "true" }
echo "[INFO] ECR 로그인 설정 중..."

# AWS 자격 증명 설정
export AWS_ACCESS_KEY_ID="${aws_access_key_id}"
export AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"
export AWS_DEFAULT_REGION="${aws_region}"

# ECR 로그인
echo "[INFO] ECR에 로그인 중..."
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin $(echo "${docker_image}" | cut -d'/' -f1)

if [ $? -eq 0 ]; then
    echo "[SUCCESS] ECR 로그인 성공"
else
    echo "[ERROR] ECR 로그인 실패"
    exit 1
fi

# 이미지 변수 설정 (ECR 이미지)
export IMAGE="${docker_image}"
echo "[INFO] ECR 이미지 사용: $IMAGE"

%{ else }
# 일반 Docker Hub 이미지 사용
export IMAGE="${docker_image}"
echo "[INFO] Docker Hub 이미지 사용: $IMAGE"
%{ endif }

# Docker 이미지 pull 및 실행
echo "[INFO] Docker 이미지 pull 중: $IMAGE"
docker pull "$IMAGE"

if [ $? -eq 0 ]; then
    echo "[SUCCESS] 이미지 pull 성공"
    
    # 기존 컨테이너 정리
    echo "[INFO] 기존 app 컨테이너 정리 중..."
    docker rm -f app 2>/dev/null || true
    
    # 새 컨테이너 실행
    echo "[INFO] 새 컨테이너 실행 중..."
    docker run -d --name app --restart always -p 3000:3000 "$IMAGE"
    
    if [ $? -eq 0 ]; then
        echo "[SUCCESS] 컨테이너 실행 성공"
        docker ps | grep app
    else
        echo "[ERROR] 컨테이너 실행 실패"
        exit 1
    fi
else
    echo "[ERROR] 이미지 pull 실패"
    exit 1
fi

echo "======================================================"
echo "[SUCCESS] 모든 초기화 작업 완료"