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

# 시스템 업데이트 및 필요한 패키지 설치
echo "[INFO] 시스템 업데이트 및 필수 패키지 설치 중..."
apt-get update -y
apt-get install -y \
  curl \
  wget \
  unzip \
  ca-certificates \
  gnupg \
  lsb-release

# Docker 설치 (공식 스크립트 사용)
echo "[INFO] Docker 설치 중..."
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
sh get-docker.sh
rm -f get-docker.sh

# deploy 사용자에 docker 그룹 권한 부여
usermod -aG docker deploy

# Docker 서비스 시작 및 활성화
systemctl start docker
systemctl enable docker

# AWS CLI 설치 (ECR 로그인용)
echo "[INFO] AWS CLI 설치 중..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# AWS CLI 설치 확인
aws --version

echo "[INFO] Docker 및 AWS CLI 설치 완료"

# ───────────────────────────────────────────────
# ECR 로그인 및 Docker 이미지 처리
# ───────────────────────────────────────────────

%{ if use_ecr == "true" }
echo "[INFO] ECR 로그인 설정 중..."

# Docker 서비스가 완전히 시작될 때까지 대기
echo "[INFO] Docker 서비스 시작 대기 중..."
sleep 10

# Docker 서비스 상태 확인
systemctl is-active docker || {
    echo "[ERROR] Docker 서비스가 실행되지 않음"
    systemctl status docker
    exit 1
}

# AWS 자격 증명 설정
export AWS_ACCESS_KEY_ID="${aws_access_key_id}"
export AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"
export AWS_DEFAULT_REGION="${aws_region}"

# ECR 레지스트리 URL 추출
ECR_REGISTRY=$(echo "${docker_image}" | cut -d'/' -f1)
echo "[INFO] ECR 레지스트리: $ECR_REGISTRY"

# ECR 로그인
echo "[INFO] ECR에 로그인 중..."
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin $ECR_REGISTRY

if [ $? -eq 0 ]; then
    echo "[SUCCESS] ECR 로그인 성공"
else
    echo "[ERROR] ECR 로그인 실패"
    # 디버깅을 위한 추가 정보
    echo "[DEBUG] 사용된 AWS 리전: ${aws_region}"
    echo "[DEBUG] ECR 레지스트리: $ECR_REGISTRY"
    aws sts get-caller-identity || echo "[ERROR] AWS 자격 증명 확인 실패"
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

# 기존 컨테이너 정리
echo "[INFO] 기존 '${container_name}' 컨테이너 정리 중..."
docker rm -f ${container_name} 2>/dev/null || true

# Docker 이미지 pull
echo "[INFO] Docker 이미지 pull 시작..."
docker pull "$IMAGE"

if [ $? -eq 0 ]; then
    echo "[SUCCESS] 이미지 pull 성공"
    
    # 새 컨테이너 실행
    echo "[INFO] 새 컨테이너 실행 중..."
    docker run -d \
        --name ${container_name} \
        --restart always \
        -p ${host_port}:${container_port} \
        "$IMAGE"
    
    if [ $? -eq 0 ]; then
        echo "[SUCCESS] 컨테이너 실행 성공"
        echo "[INFO] 컨테이너 상태:"
        docker ps | grep ${container_name}
        
        echo "[INFO] 컨테이너 로그 (최근 10줄):"
        docker logs --tail 10 ${container_name}
        
        # deploy 사용자도 Docker 명령을 사용할 수 있도록 권한 설정
        echo "[INFO] deploy 사용자 Docker 권한 설정..."
        usermod -aG docker deploy
        
        # docker.sock 권한 설정
        chmod 666 /var/run/docker.sock
        
    else
        echo "[ERROR] 컨테이너 실행 실패"
        docker logs ${container_name} 2>/dev/null || echo "[ERROR] 컨테이너 로그를 가져올 수 없음"
        exit 1
    fi
else
    echo "[ERROR] 이미지 pull 실패"
    echo "[DEBUG] Docker 데몬 상태:"
    systemctl status docker --no-pager -l
    exit 1
fi

echo "======================================================"
echo "[SUCCESS] 모든 초기화 작업 완료"