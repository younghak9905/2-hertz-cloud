#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1
echo "OpenVPN Access Server 설치 스크립트 시작: $(date)"

CUSTOM_PASSWORD="${admin_password}"

OPENVPN_HOME="/home/openvpnas"
CONFIG_DIR="${OPENVPN_HOME}/config"

# 기존 설정 초기화 (필요 시 주석 제거)
rm -rf /usr/local/openvpn_as/etc/db

mkdir -p "$CONFIG_DIR"
chown openvpnas:openvpnas "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

# 자동 응답
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

echo "OpenVPN Access Server 초기 설정 시작..."
/usr/local/openvpn_as/bin/ovpn-init < /tmp/as-answers
rm /tmp/as-answers

echo "관리자 비밀번호 설정 중... ($CUSTOM_PASSWORD)"
if sacli --user openvpn --new_pass "$CUSTOM_PASSWORD" SetLocalPassword > /dev/null; then
    echo "관리자 비밀번호가 성공적으로 변경되었습니다."
    echo "OpenVPN Admin 비밀번호: $CUSTOM_PASSWORD" > "$CONFIG_DIR/openvpn-password.txt"
    chmod 600 "$CONFIG_DIR/openvpn-password.txt"
    chown openvpnas:openvpnas "$CONFIG_DIR/openvpn-password.txt"

    echo "OpenVPN Admin 비밀번호: $CUSTOM_PASSWORD" > /root/openvpn-password.txt
    chmod 600 /root/openvpn-password.txt
else
    echo "관리자 비밀번호 변경 실패. sacli 명령어가 실패했습니다."
    if [ -f /usr/local/openvpn_as/init.log ]; then
        PASSWORD=$(grep -o "password '[^']*'" /usr/local/openvpn_as/init.log | sed "s/password '//;s/'//")
        if [ -n "$PASSWORD" ]; then
            echo "초기 생성된 비밀번호: $PASSWORD" > "$CONFIG_DIR/openvpn-initial-password.txt"
            chmod 600 "$CONFIG_DIR/openvpn-initial-password.txt"
            chown openvpnas:openvpnas "$CONFIG_DIR/openvpn-initial-password.txt"
        fi
    fi
fi

SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "OpenVPN Access Server 관리자 UI: https://$SERVER_IP:943/admin" > "$CONFIG_DIR/openvpn-info.txt"
echo "OpenVPN Access Server 클라이언트 UI: https://$SERVER_IP:943/" >> "$CONFIG_DIR/openvpn-info.txt"
echo "사용자 이름: openvpn" >> "$CONFIG_DIR/openvpn-info.txt"
echo "비밀번호: $CUSTOM_PASSWORD" >> "$CONFIG_DIR/openvpn-info.txt"
chmod 600 "$CONFIG_DIR/openvpn-info.txt"
chown openvpnas:openvpnas "$CONFIG_DIR/openvpn-info.txt"

cp "$CONFIG_DIR/openvpn-info.txt" /root/openvpn-info.txt
chmod 600 /root/openvpn-info.txt

# IP 포워딩 활성화
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p

# README 생성
cat > "$OPENVPN_HOME/README.txt" << EOF
=== OpenVPN Access Server 사용 안내 ===

1. 관리자 웹 인터페이스:
   URL: https://$SERVER_IP:943/admin
   사용자 이름: openvpn
   비밀번호: $CUSTOM_PASSWORD

2. 클라이언트 웹 인터페이스:
   URL: https://$SERVER_IP:943/

4. 서비스 관리:
   - 상태 확인: sudo service openvpnas status
   - 재시작: sudo service openvpnas restart
   - 중지: sudo service openvpnas stop
   - 시작: sudo service openvpnas start

5. 주요 로그 파일:
   - /var/log/openvpnas.log
   - /usr/local/openvpn_as/log/openvpn.log
EOF

chmod 644 "$OPENVPN_HOME/README.txt"
chown openvpnas:openvpnas "$OPENVPN_HOME/README.txt"

# sudo 권한 부여
if ! grep -q "openvpnas" /etc/sudoers; then
  echo "openvpnas ALL=(ALL) NOPASSWD: /usr/local/openvpn_as/scripts/*, /bin/systemctl * openvpnas, /bin/service openvpnas *" >> /etc/sudoers
fi

# 서비스 재시작
echo "서비스 재시작 중..."
service openvpnas restart
sleep 5
service openvpnas status

echo "✅ OpenVPN Access Server 설치 완료: $(date)"