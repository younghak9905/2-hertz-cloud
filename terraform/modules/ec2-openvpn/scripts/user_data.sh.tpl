#!/bin/bash

# 기본 시스템 업데이트 및 도구 설치
yum update -y
yum install -y wget net-tools jq awscli

# OpenVPN 설치 스크립트 저장
cat > /home/ec2-user/openvpn-install.sh << 'OPENVPNEOF'
${openvpn_script}
OPENVPNEOF

chmod +x /home/ec2-user/openvpn-install.sh
chown ec2-user:ec2-user /home/ec2-user/openvpn-install.sh

# OpenVPN 자동 설치 (ec2-user 권한으로 실행)
runuser -l ec2-user -c "/home/ec2-user/openvpn-install.sh" <<EOF
1
client1
EOF

# .ovpn 파일 이동 및 소유자 변경
if [ -f /root/client1.ovpn ]; then
  mv /root/client1.ovpn /home/ec2-user/client1.ovpn
  chown ec2-user:ec2-user /home/ec2-user/client1.ovpn
fi

# 안내 메시지 생성
cat > /home/ec2-user/README.txt << READMEEOF
=== OpenVPN 설치 안내 ===

OpenVPN이 자동으로 설치되었으며, client1.ovpn 파일이 생성되어 있습니다.

1. 다음 명령어로 .ovpn 파일을 로컬로 다운로드하세요:
   scp -i your-key.pem ec2-user@$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):/home/ec2-user/client1.ovpn .

2. OpenVPN Connect 앱에서 .ovpn 파일을 가져와 사용하세요.
READMEEOF

chown ec2-user:ec2-user /home/ec2-user/README.txt