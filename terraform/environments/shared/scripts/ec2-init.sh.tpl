#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1
echo "### [START] UserData Script - $(date)"

# 1. 시스템 패키지 업데이트
yum update -y

# 2. deploy 유저 생성 (비밀번호 없이, 홈 디렉토리 포함)
if ! id deploy &>/dev/null; then
  useradd -m deploy
fi

# 3. deploy 유저를 docker 그룹에만 추가 (sudo 권한 부여하지 않음)
usermod -aG docker deploy || true

# 4. Docker 설치 (Amazon Linux 2는 amazon-linux-extras 사용)
if ! command -v docker >/dev/null 2>&1; then
  amazon-linux-extras install docker -y
  yum install -y docker
fi

systemctl enable docker
systemctl start docker

# 5. AWS CLI(v2) 설치 (Amazon Linux 2는 기본 설치돼있을 수 있음. 없으면 설치)
if ! command -v aws >/dev/null 2>&1; then
  yum install -y unzip
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  ./aws/install
  export PATH=$PATH:/usr/local/bin
fi

# 6. CodeDeploy Agent 설치
if ! systemctl is-active --quiet codedeploy-agent; then
  yum install -y ruby wget
  REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
  cd /home/deploy || cd /tmp
  wget https://aws-codedeploy-$${REGION}.s3.$${REGION}.amazonaws.com/latest/install
  chmod +x ./install
  ./install auto
  systemctl enable codedeploy-agent
  systemctl start codedeploy-agent
fi

# 7. (옵션) Docker Compose v2 설치
if ! command -v docker-compose >/dev/null 2>&1; then
  DOCKER_COMPOSE_VERSION="2.29.2"
  curl -L "https://github.com/docker/compose/releases/download/v$${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || true
fi

echo "### [COMPLETE] UserData Script - $(date)"