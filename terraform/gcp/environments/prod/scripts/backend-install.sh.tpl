#!/bin/bash
set -e

# 로그 기록
exec > >(tee -a /var/log/base-init.log) 2>&1

echo "========== 기본 초기화 시작 =========="

# deploy 사용자 생성 및 SSH 키 등록# deploy 사용자 생성 및 SSH 키 등록
if id "deploy" &>/dev/null; then
  echo "[INFO] deploy 사용자 이미 존재함"
else
  useradd -m -s /bin/bash deploy
  mkdir -p /home/deploy/.ssh
fi
# deploy 사용자 생성 및 SSH 키 등록
echo "${deploy_ssh_public_key}" > /home/deploy/.ssh/authorized_keys
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh
# deploy 사용자에 제한 sudo 권한 부여 (docker / openvpnas 제어용)
if ! grep -q "deploy" /etc/sudoers; then
  echo "deploy ALL=(ALL) NOPASSWD: /bin/systemctl * docker, /bin/systemctl * openvpnas, /bin/service openvpnas *" >> /etc/sudoers
fi

# deploy 사용자에 docker 그룹 권한 부여
usermod -aG docker deploy

echo "[INFO] 기본 초기화 완료"

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
export AWS_REGION="${aws_region}"

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

ENV_FILE="/home/deploy/app.env"
DIR_PATH=$(dirname "$ENV_FILE")
if [ ! -d "$DIR_PATH" ]; then
  mkdir -p "$DIR_PATH"
  chown $(whoami) "$DIR_PATH"
fi

> "$ENV_FILE"
echo "# Spring Boot 환경변수 (SSM→.env, DB_HOST는 로컬 IP로 덮어쓰기)" >> "$ENV_FILE"


# SSM 파라미터 prefix
SSM_PATH="${ssm_path}"

PARAM_JSON=$(aws ssm get-parameters-by-path \
  --path "$SSM_PATH" \
  --recursive \
  --with-decryption \
  --region "$AWS_REGION" \
  --output json)
echo "$PARAM_JSON" | jq -r '.Parameters[] | "\(.Name | ltrimstr("'"$SSM_PATH"'"))=\(.Value)"' >> "$ENV_FILE"


echo "✅ SSM 파라미터를 $ENV_FILE 파일로 저장 완료"
LOCAL_DB_HOST="${db_host}"
echo "DB_HOST=$LOCAL_DB_HOST" >> "$ENV_FILE"

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
        --env-file $ENV_FILE \
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