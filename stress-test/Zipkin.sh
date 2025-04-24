#!/bin/bash

echo "✅ Docker 설치 중..."
sudo yum install -y docker
sudo service docker start
sudo usermod -aG docker ec2-user
newgrp docker

echo "✅ 개발 도구 및 wrk 의존성 설치 중..."
sudo yum groupinstall -y "Development Tools"
sudo yum install -y git libev-devel openssl-devel

echo "✅ wrk 설치 중..."
git clone https://github.com/wg/wrk.git
cd wrk
make
sudo cp wrk /usr/local/bin/
cd ..
rm -rf wrk

echo "✅ Zipkin Docker 컨테이너 실행 중..."
docker run -d \
  --cpus="1.5" \
  --memory="3g" \
  -p 9411:9411 \
  --name zipkin \
  openzipkin/zipkin

echo "🎉 설치 완료! Zipkin은 http://<your-ip>:9411 에서 접근할 수 있습니다."
echo "👉 wrk 테스트 예시: wrk -t8 -c100 -d30s http://localhost:9411/api/v2/services"
