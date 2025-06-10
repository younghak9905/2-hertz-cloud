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
DEVICE="/dev/disk/by-id/google-mysql-data"
MOUNT_POINT="/mnt/tmp"

# 1. 마운트 디렉토리 생성
sudo mkdir -p $MOUNT_POINT

# 2. 디스크가 ext4로 포맷되어 있지 않다면, 포맷 (데이터 모두 삭제됨, 최초 1회만!)
if ! sudo blkid $DEVICE | grep -q 'ext4'; then
  sudo mkfs.ext4 -F $DEVICE
fi

# 3. /etc/fstab에 등록 (중복 방지)
if ! grep -q "$DEVICE" /etc/fstab; then
  echo "$DEVICE $MOUNT_POINT ext4 defaults 0 2" | sudo tee -a /etc/fstab
fi

# 4. 즉시 마운트 (fstab에 등록된 대로)
sudo mount $MOUNT_POINT

# 5. mysql-data 서브디렉토리 생성
sudo mkdir -p $MOUNT_POINT/mysql-data

# 로그 설정
exec > >(tee /var/log/user-data.log) 2>&1
echo "======================================================"
# Docker 설치 (공식 스크립트 사용)
dpkg -i $${MOUNT_POINT}/containerd.io_*.deb $${MOUNT_POINT}/docker-ce-cli_*.deb $${MOUNT_POINT}/docker-ce_*.deb || apt-get install -f -y

# deploy 사용자에 docker 그룹 권한 부여
usermod -aG docker deploy

docker load -i $${MOUNT_POINT}/mysql-8.0.tar

docker run -d \
  --name mysql \
  --restart always \
  -e MYSQL_ROOT_PASSWORD="${rootpasswd}" \
  -e MYSQL_DATABASE="${db_name}" \
  -e MYSQL_USER="${user_name}" \
  -e MYSQL_PASSWORD="${rootpasswd}" \
  -v $${MOUNT_POINT}/mysql-data:/var/lib/mysql \
  -p 3306:3306 \
  mysql:8.0

echo "[startup] MySQL container launched with data on $${MOUNT_POINT}"


# Redis 이미지 로드 및 실행
echo "[INFO] Redis 컨테이너 시작"
docker load -i $MOUNT_POINT/redis-7.4.2.tar

docker run -d \
  --name redis \
  --restart unless-stopped \
  -e REDIS_PASSWORD="${redis_password}" \
  -v redis_data:/data \
  -p 6379:6379 \
  "redis:7.2.4" \
  redis-server --requirepass "${redis_password}"