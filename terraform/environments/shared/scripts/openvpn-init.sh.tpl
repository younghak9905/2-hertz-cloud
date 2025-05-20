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

# 더 포괄적인 자동 응답 파일 생성 (NAT 옵션을 2로 수정)
cat > /tmp/as-answers << "EOF"
yes
yes
1
yes
2
943
443
1194
yes
yes
EOF

# 초기 설정 자동화 실행
echo "OpenVPN Access Server 초기 설정 시작..."
/usr/local/openvpn_as/bin/ovpn-init < /tmp/as-answers

# 설정 완료 후 응답 파일 제거
rm /tmp/as-answers

# 사용자 지정 관리자 비밀번호 설정
echo "관리자 비밀번호 설정 중... ($${CUSTOM_PASSWORD})"

# openvpn 관리자 계정의 비밀번호 변경
if sacli --user openvpn --new_pass "$${CUSTOM_PASSWORD}" SetLocalPassword > /dev/null; then
    echo "관리자 비밀번호가 성공적으로 변경되었습니다."
    # 비밀번호 정보 저장
    echo "OpenVPN Admin 비밀번호: $${CUSTOM_PASSWORD}" > $${CONFIG_DIR}/openvpn-password.txt
    chmod 600 $${CONFIG_DIR}/openvpn-password.txt
    chown openvpnas:openvpnas $${CONFIG_DIR}/openvpn-password.txt
    echo "비밀번호가 $${CONFIG_DIR}/openvpn-password.txt에 저장되었습니다."
    
    # 루트 계정에도 복사 (관리 목적)
    echo "OpenVPN Admin 비밀번호: $${CUSTOM_PASSWORD}" > /root/openvpn-password.txt
    chmod 600 /root/openvpn-password.txt
else
    echo "관리자 비밀번호 변경 실패. sacli 명령어가 실패했습니다."
    # 기존 방식으로 초기 비밀번호 확인 시도
    if [ -f /usr/local/openvpn_as/init.log ]; then
        PASSWORD=$$(grep -o "password '[^']*'" /usr/local/openvpn_as/init.log | sed "s/password '//;s/'//")
        if [ -n "$${PASSWORD}" ]; then
            echo "초기 생성된 비밀번호: $${PASSWORD}" > $${CONFIG_DIR}/openvpn-initial-password.txt
            chmod 600 $${CONFIG_DIR}/openvpn-initial-password.txt
            chown openvpnas:openvpnas $${CONFIG_DIR}/openvpn-initial-password.txt
            echo "초기 비밀번호가 $${CONFIG_DIR}/openvpn-initial-password.txt에 저장되었습니다."
        fi
    fi
fi

# 서버 IP 확인 및 저장
SERVER_IP=$$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
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
cat > $${OPENVPN_HOME}/README.txt << "EOF"
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