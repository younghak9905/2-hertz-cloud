#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1
echo "OpenVPN Access Server 설치 스크립트 시작: $(date)"

CUSTOM_PASSWORD="${admin_password}"

OPENVPN_HOME="/home/openvpnas"
CONFIG_DIR="$$OPENVPN_HOME/config"

mkdir -p $$CONFIG_DIR
chown openvpnas:openvpnas $$CONFIG_DIR
chmod 700 $$CONFIG_DIR

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

echo "관리자 비밀번호 설정 중... ($$CUSTOM_PASSWORD)"
if sacli --user openvpn --new_pass "$$CUSTOM_PASSWORD" SetLocalPassword > /dev/null; then
    echo "관리자 비밀번호가 성공적으로 변경되었습니다."
    echo "OpenVPN Admin 비밀번호: $$CUSTOM_PASSWORD" > $$CONFIG_DIR/openvpn-password.txt
    chmod 600 $$CONFIG_DIR/openvpn-password.txt
    chown openvpnas:openvpnas $$CONFIG_DIR/openvpn-password.txt
    echo "비밀번호가 $$CONFIG_DIR/openvpn-password.txt에 저장되었습니다."

    echo "OpenVPN Admin 비밀번호: $$CUSTOM_PASSWORD" > /root/openvpn-password.txt
    chmod 600 /root/openvpn-password.txt
else
    echo "관리자 비밀번호 변경 실패. sacli 명령어가 실패했습니다."
    if [ -f /usr/local/openvpn_as/init.log ]; then
        PASSWORD=$$(grep -o "password '[^']*'" /usr/local/openvpn_as/init.log | sed "s/password '//;s/'//")
        if [ -n "$$PASSWORD" ]; then
            echo "초기 생성된 비밀번호: $$PASSWORD" > $$CONFIG_DIR/openvpn-initial-password.txt
            chmod 600 $$CONFIG_DIR/openvpn-initial-password.txt
            chown openvpnas:openvpnas $$CONFIG_DIR/openvpn-initial-password.txt
            echo "초기 비밀번호가 $$CONFIG_DIR/openvpn-initial-password.txt에 저장되었습니다."
        fi
    fi
fi

SERVER_IP=$$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "OpenVPN Access Server 관리자 UI: https://$$SERVER_IP:943/admin" > $$CONFIG_DIR/openvpn-info.txt
echo "OpenVPN Access Server 클라이언트 UI: https://$$SERVER_IP:943/" >> $$CONFIG_DIR/openvpn-info.txt
echo "사용자 이름: openvpn" >> $$CONFIG_DIR/openvpn-info.txt
echo "비밀번호: $$CUSTOM_PASSWORD" >> $$CONFIG_DIR/openvpn-info.txt
chmod 600 $$CONFIG_DIR/openvpn-info.txt
chown openvpnas:openvpnas $$CONFIG_DIR/openvpn-info.txt

cp $$CONFIG_DIR/openvpn-info.txt /root/openvpn-info.txt
chmod 600 /root/openvpn-info.txt

cat > $$OPENVPN_HOME/get-profiles.sh << "EOF"
#!/bin/bash
if [ $$# -lt 1 ]; then
  echo "사용법: $$0 <사용자명> [출력_디렉토리]"
  exit 1
fi
USERNAME=$$1
OUTPUT_DIR="${2:-$$HOME/profiles}"
mkdir -p "$$OUTPUT_DIR"
if sacli --user "$$USERNAME" AutoGenerateOnBehalfOf; then
  PROFILE="/usr/local/openvpn_as/profiles/$$USERNAME.ovpn"
  if [ -f "$$PROFILE" ]; then
    cp "$$PROFILE" "$$OUTPUT_DIR/"
    echo "프로필이 $$OUTPUT_DIR/$$USERNAME.ovpn에 저장되었습니다."
  else
    echo "오류: 프로필 파일을 찾을 수 없습니다."
    exit 1
  fi
else
  echo "오류: 프로필 생성에 실패했습니다."
  exit 1
fi
EOF

chmod 755 $$OPENVPN_HOME/get-profiles.sh
chown openvpnas:openvpnas $$OPENVPN_HOME/get-profiles.sh

cat > $$OPENVPN_HOME/add-user.sh << "EOF"
#!/bin/bash
if [ $$# -lt 2 ]; then
  echo "사용법: $$0 <사용자명> <비밀번호>"
  exit 1
fi
USERNAME=$$1
PASSWORD=$$2
if sacli --user "$$USERNAME" --key "prop_superuser" --value "false" UserPropPut > /dev/null; then
  if sacli --user "$$USERNAME" --new_pass "$$PASSWORD" SetLocalPassword > /dev/null; then
    echo "사용자 $$USERNAME이(가) 성공적으로 추가되었습니다."
    if sacli --user "$$USERNAME" AutoGenerateOnBehalfOf > /dev/null; then
      echo "프로필이 생성되었습니다."
    else
      echo "경고: 프로필 생성에 실패했습니다."
    fi
  else
    echo "오류: 비밀번호 설정에 실패했습니다."
    exit 1
  fi
else
  echo "오류: 사용자 추가에 실패했습니다."
  exit 1
fi
EOF

chmod 755 $$OPENVPN_HOME/add-user.sh
chown openvpnas:openvpnas $$OPENVPN_HOME/add-user.sh

echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p

cat > $$OPENVPN_HOME/README.txt << "EOF"
=== OpenVPN Access Server 사용 안내 ===

1. 관리자 웹 인터페이스:
   URL: https://SERVER_IP:943/admin
   사용자 이름: openvpn
   비밀번호: ADMIN_PASSWORD

2. 클라이언트 웹 인터페이스:
   URL: https://SERVER_IP:943/

3. 유용한 스크립트:
   - add-user.sh: 새 사용자 추가
     사용법: ./add-user.sh <사용자명> <비밀번호>
   - get-profiles.sh: 사용자 프로필 파일 다운로드
     사용법: ./get-profiles.sh <사용자명> [출력_디렉토리]

4. 서비스 관리:
   - 상태 확인: sudo service openvpnas status
   - 재시작: sudo service openvpnas restart
   - 중지: sudo service openvpnas stop
   - 시작: sudo service openvpnas start

5. 주요 로그 파일:
   - /var/log/openvpnas.log
   - /usr/local/openvpn_as/log/openvpn.log
EOF

sed -i "s/SERVER_IP/$$SERVER_IP/g" $$OPENVPN_HOME/README.txt
sed -i "s/ADMIN_PASSWORD/$$CUSTOM_PASSWORD/g" $$OPENVPN_HOME/README.txt
chmod 644 $$OPENVPN_HOME/README.txt
chown openvpnas:openvpnas $$OPENVPN_HOME/README.txt

if ! grep -q "openvpnas" /etc/sudoers; then
  echo "openvpnas ALL=(ALL) NOPASSWD: /usr/local/openvpn_as/scripts/*, /bin/systemctl * openvpnas, /bin/service openvpnas *" >> /etc/sudoers
fi

service openvpnas restart
sleep 5
service openvpnas status

echo "✅ OpenVPN Access Server 설치 완료: $(date)"