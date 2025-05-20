#!/bin/bash
# 로그 설정
exec > >(tee /var/log/user-data.log) 2>&1
echo "======================================================"
echo "OpenVPN Access Server 설치 스크립트 시작: $(date)"
echo "======================================================"

# 변수 설정 - 외부에서 받은 인자 사용
CUSTOM_PASSWORD="${admin_password}"
echo "사용할 비밀번호: $${CUSTOM_PASSWORD}"

# 디렉토리 설정
OPENVPN_HOME="/home/openvpnas"
CONFIG_DIR="$${OPENVPN_HOME}/config"
mkdir -p $${CONFIG_DIR}
chown openvpnas:openvpnas $${CONFIG_DIR}
chmod 700 $${CONFIG_DIR}

# 서버 IP 확인
SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
HOSTNAME=$(hostname -f)
echo "서버 Public IP: $${SERVER_IP}, Private IP: $${PRIVATE_IP}, 호스트명: $${HOSTNAME}"

# 배치 모드로 OpenVPN 초기화 (모든 설정을 한번에 적용)
echo "OpenVPN Access Server 배치 모드 초기화 시작..."
/usr/local/openvpn_as/bin/ovpn-init --batch \
--force \
--ec2 \
--local_auth=1 \
--no_start \
--host=$${SERVER_IP} \
--iface=eth0 \
--admin_user=openvpn \
--admin_pw="$${CUSTOM_PASSWORD}" \
--license_agreement=yes \
--verb=3 \
--ca_key_type=secp384r1 \
--web_key_type=secp384r1 \
--reroute_gw=1 \
--reroute_dns=0 \
--private_subnets=1 \
--vpn_tcp_port=443 \
--cs_priv_port=943 \
--cs_pub_port=943

echo "OpenVPN Access Server 배치 모드 초기화 완료"

# 서비스 시작
echo "OpenVPN 서비스 시작 중..."
service openvpnas start
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