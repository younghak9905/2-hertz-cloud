#!/bin/bash
# 로그 설정
exec > >(tee /var/log/user-data.log) 2>&1
echo "OpenVPN Access Server 설치 스크립트 시작: $(date)"

# 변수 설정 - 외부에서 받은 인자 사용
CUSTOM_PASSWORD="${admin_password}"

# AMI 인스턴스는 이미 OpenVPN이 설치되어 있으므로 초기 설정만 진행

# openvpnas 사용자 홈 디렉토리 설정
OPENVPN_HOME="/home/openvpnas"
CONFIG_DIR="$${OPENVPN_HOME}/config"

# 설정 디렉토리 생성
mkdir -p $${CONFIG_DIR}
chown openvpnas:openvpnas $${CONFIG_DIR}
chmod 700 $${CONFIG_DIR}

# 기존 설정 강제 삭제 (안전 장치 제거)
echo "기존 OpenVPN 설정 강제 초기화 중..."
rm -rf /usr/local/openvpn_as/etc/db/* 2>/dev/null || true

# DELETE 문제를 우회하기 위해 expect 스크립트 사용
echo "expect 패키지 설치 중..."
apt-get update -y >/dev/null 2>&1
apt-get install -y expect >/dev/null 2>&1

# expect 스크립트 생성
cat > /tmp/openvpn-expect.sh << 'EXPECTEOF'
#!/usr/bin/expect -f
set timeout 120

# 시작
spawn /usr/local/openvpn_as/bin/ovpn-init

# 기존 설정 삭제 확인 (나타날 경우)
expect {
    "Please enter 'DELETE' to delete existing configuration:" {
        send "DELETE\r"
        exp_continue
    }
    "Please enter 'yes' to indicate your agreement" {}
}

# 라이센스 동의
send "yes\r"

# 기본 노드 확인
expect "Press ENTER for default \[yes\]:"
send "\r"

# 네트워크 인터페이스 선택
expect "Please enter the option number from the list above"
send "1\r"

# CA 알고리즘
expect "Press ENTER for default \[secp384r1\]:"
send "\r"

# 웹 인증서 알고리즘
expect "Press ENTER for default \[secp384r1\]:"
send "\r"

# Admin UI 포트
expect "Press ENTER for default \[943\]:"
send "\r"

# OpenVPN 데몬 포트
expect "Press ENTER for default \[443\]:"
send "\r"

# 클라이언트 트래픽 라우팅
expect "Press ENTER for default \[yes\]:"
send "yes\r"

# DNS 트래픽 라우팅
expect "Press ENTER for default \[yes\]:"
send "no\r"

# 프라이빗 서브넷 접근
expect "Press ENTER for default \[yes\]:"
send "yes\r"

# 관리자 로그인
expect "Press ENTER for default \[yes\]:"
send "yes\r"

# 관리자 비밀번호 - 빈칸으로 두고 자동 생성
expect "Type a password for the 'openvpn' account"
send "\r"

# 자동 생성된 비밀번호 출력 캡처
expect "Please, remember this password"

# 라이센스 키
expect "Please specify your Activation key"
send "\r"

expect eof
EXPECTEOF

# expect 스크립트 실행
chmod +x /tmp/openvpn-expect.sh
/tmp/openvpn-expect.sh
rm -f /tmp/openvpn-expect.sh

# 꼭! 서비스 재시작 (설정 반영)
service openvpnas restart

# 서비스가 완전히 뜰 때까지 대기
echo "OpenVPN 서비스가 시작될 때까지 대기 중..."
for i in {1..30}; do
    if netstat -tnlp | grep -q ':943'; then
        echo "OpenVPN admin port opened!"
        break
    fi
    sleep 1
done

# 사용자 지정 관리자 비밀번호 설정
echo "관리자 비밀번호 설정 중... ($${CUSTOM_PASSWORD})"
/usr/local/openvpn_as/scripts/sacli --user openvpn --new_pass "$${CUSTOM_PASSWORD}" SetLocalPassword

# 서버 IP 확인 및 저장
SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "OpenVPN Access Server 관리자 UI: https://$${SERVER_IP}:943/admin" > $${CONFIG_DIR}/openvpn-info.txt
echo "OpenVPN Access Server 클라이언트 UI: https://$${SERVER_IP}:943/" >> $${CONFIG_DIR}/openvpn-info.txt
echo "사용자 이름: openvpn" >> $${CONFIG_DIR}/openvpn-info.txt
echo "비밀번호: $${CUSTOM_PASSWORD}" >> $${CONFIG_DIR}/openvpn-info.txt
chmod 600 $${CONFIG_DIR}/openvpn-info.txt
chown openvpnas:openvpnas $${CONFIG_DIR}/openvpn-info.txt

# 루트 계정에도 정보 저장
cp $${CONFIG_DIR}/openvpn-info.txt /root/openvpn-info.txt
chmod 600 /root/openvpn-info.txt

# 시스템 최적화 설정
echo "시스템 최적화 설정 적용 중..."
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p

# README 파일 생성
cat > $${OPENVPN_HOME}/README.txt << 'EOF'
=== OpenVPN Access Server 사용 안내 ===

1. 관리자 웹 인터페이스:
   URL: https://SERVER_IP:943/admin
   사용자 이름: openvpn
   비밀번호: ADMIN_PASSWORD

2. 클라이언트 웹 인터페이스:
   URL: https://SERVER_IP:943/

3. 서비스 관리:
   - 상태 확인: sudo service openvpnas status
   - 재시작: sudo service openvpnas restart
   - 중지: sudo service openvpnas stop
   - 시작: sudo service openvpnas start

4. 주요 로그 파일:
   - /var/log/openvpnas.log
   - /usr/local/openvpn_as/log/openvpn.log
EOF

# README 파일에 실제 IP와 비밀번호 채우기
sed -i "s/SERVER_IP/$${SERVER_IP}/g" $${OPENVPN_HOME}/README.txt
sed -i "s/ADMIN_PASSWORD/$${CUSTOM_PASSWORD}/g" $${OPENVPN_HOME}/README.txt

chmod 644 $${OPENVPN_HOME}/README.txt
chown openvpnas:openvpnas $${OPENVPN_HOME}/README.txt

# openvpnas 사용자에게 sudo 권한 부여 (선택적)
if ! grep -q "openvpnas" /etc/sudoers; then
  echo "openvpnas ALL=(ALL) NOPASSWD: /usr/local/openvpn_as/scripts/*, /bin/systemctl * openvpnas, /bin/service openvpnas *" >> /etc/sudoers
fi

# 서비스 재시작 및 상태 확인
echo "OpenVPN Access Server 서비스 재시작 중..."
service openvpnas restart
sleep 5
service openvpnas status

echo "OpenVPN Access Server 설치 스크립트 완료: $(date)"