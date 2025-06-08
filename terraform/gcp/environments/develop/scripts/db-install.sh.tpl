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

# 마운트 디렉토리 생성
mkdir -p $${MOUNT_POINT}

# /etc/fstab에 등록하여 재부팅 시 자동 마운트
if ! grep -q "$${DEVICE}" /etc/fstab; then
  echo "$${DEVICE} $${MOUNT_POINT} ext4 defaults 0 2" >> /etc/fstab
fi

# 즉시 마운트
mount $${MOUNT_POINT}

# 4. mysql-data 서브디렉토리 생성
mkdir -p $MOUNT_POINT/mysql-data


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