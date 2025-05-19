#!/bin/bash
# OpenVPN 인증서 기반 설치 자동화 스크립트
# 실행 방법: sudo bash openvpn-install.sh

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 루트 권한 확인
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}이 스크립트는 root 권한으로 실행해야 합니다.${NC}"
   echo "sudo bash $0 실행해주세요."
   exit 1
fi

# 서버 IP 가져오기
SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
CLIENT_NAME="client1_$(date +%Y%m%d%H%M%S)"

echo -e "${GREEN}OpenVPN 인증서 기반 설치 스크립트를 시작합니다...${NC}"
echo -e "${YELLOW}서버 IP: ${SERVER_IP}${NC}"

# 1. 필요한 패키지 설치
echo -e "\n${GREEN}[1/8] 필요한 패키지를 설치합니다...${NC}"
amazon-linux-extras install epel -y
yum install -y openvpn easy-rsa

# 2. EasyRSA 설정
echo -e "\n${GREEN}[2/8] EasyRSA를 설정합니다...${NC}"
mkdir -p /etc/openvpn/easy-rsa
cp -r /usr/share/easy-rsa/3/* /etc/openvpn/easy-rsa/
cd /etc/openvpn/easy-rsa

# 3. PKI 초기화 및 CA 생성
echo -e "\n${GREEN}[3/8] PKI를 초기화하고 CA를 생성합니다...${NC}"
./easyrsa init-pki
echo -e "OpenVPN-CA\n" | ./easyrsa build-ca nopass

# 4. 서버 인증서 및 키 생성
echo -e "\n${GREEN}[4/8] 서버 인증서 및 키를 생성합니다...${NC}"
echo -e "\n" | ./easyrsa gen-req server nopass
echo -e "yes\n" | ./easyrsa sign-req server server

# 5. DH 파라미터 및 TLS 키 생성
echo -e "\n${GREEN}[5/8] DH 파라미터 및 TLS 키를 생성합니다...${NC}"
./easyrsa gen-dh
openvpn --genkey --secret /etc/openvpn/ta.key

# 6. 클라이언트 인증서 및 키 생성
echo -e "\n${GREEN}[6/8] 클라이언트 인증서 및 키를 생성합니다...${NC}"
echo -e "\n" | ./easyrsa gen-req $CLIENT_NAME nopass
echo -e "yes\n" | ./easyrsa sign-req client $CLIENT_NAME

# 7. 서버 구성 파일 생성
echo -e "\n${GREEN}[7/8] 서버 구성 파일을 생성합니다...${NC}"
mkdir -p /var/log/openvpn
chmod 755 /var/log/openvpn

cat > /etc/openvpn/server.conf << EOF
port 1194
proto udp
dev tun

ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key /etc/openvpn/easy-rsa/pki/private/server.key
dh /etc/openvpn/easy-rsa/pki/dh.pem
tls-auth /etc/openvpn/ta.key 0

server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

keepalive 10 120
user nobody
group nobody
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
log /var/log/openvpn/openvpn.log
verb 3
EOF

# 8. 클라이언트 구성 파일 생성
echo -e "\n${GREEN}[8/8] 클라이언트 구성 파일을 생성합니다...${NC}"

cat > /home/ec2-user/$CLIENT_NAME.ovpn << EOF
client
dev tun
proto udp
remote $SERVER_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verb 3

<ca>
$(cat /etc/openvpn/easy-rsa/pki/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/easy-rsa/pki/issued/$CLIENT_NAME.crt)
</cert>
<key>
$(cat /etc/openvpn/easy-rsa/pki/private/$CLIENT_NAME.key)
</key>
<tls-auth>
$(cat /etc/openvpn/ta.key)
</tls-auth>
key-direction 1
EOF

# 클라이언트 생성 스크립트 작성
cat > /home/ec2-user/create-client.sh << 'CLIENTSCRIPT'
#!/bin/bash
# 새 OpenVPN 클라이언트 생성 스크립트

if [ $# -ne 1 ]; then
    echo "사용법: $0 <클라이언트_이름>"
    exit 1
fi

CLIENT_NAME=$1
SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

cd /etc/openvpn/easy-rsa
sudo ./easyrsa gen-req $CLIENT_NAME nopass
sudo ./easyrsa sign-req client $CLIENT_NAME

sudo bash -c "cat > /home/ec2-user/$CLIENT_NAME.ovpn << EOF
client
dev tun
proto udp
remote $SERVER_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verb 3

<ca>
\$(cat /etc/openvpn/easy-rsa/pki/ca.crt)
</ca>
<cert>
\$(cat /etc/openvpn/easy-rsa/pki/issued/$CLIENT_NAME.crt)
</cert>
<key>
\$(cat /etc/openvpn/easy-rsa/pki/private/$CLIENT_NAME.key)
</key>
<tls-auth>
\$(cat /etc/openvpn/ta.key)
</tls-auth>
key-direction 1
EOF"

echo "클라이언트 구성 파일이 생성되었습니다: /home/ec2-user/$CLIENT_NAME.ovpn"
CLIENTSCRIPT

chmod +x /home/ec2-user/create-client.sh
chown ec2-user:ec2-user /home/ec2-user/create-client.sh
chown ec2-user:ec2-user /home/ec2-user/$CLIENT_NAME.ovpn

# IP 포워딩 활성화
echo -e "\n${GREEN}IP 포워딩을 활성화합니다...${NC}"
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p

# iptables 규칙 추가
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
iptables -A FORWARD -i tun0 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o tun0 -j ACCEPT
yum install -y iptables-services
service iptables save
systemctl enable iptables

# OpenVPN 서비스 시작 및 활성화
echo -e "\n${GREEN}OpenVPN 서비스를 시작합니다...${NC}"
systemctl enable openvpn@server
systemctl restart openvpn@server

# 상태 확인 스크립트 생성
cat > /home/ec2-user/openvpn-status.sh << 'EOF'
#!/bin/bash
echo "=== OpenVPN 서비스 상태 ==="
sudo systemctl status openvpn@server

echo -e "\n=== 연결된 클라이언트 ==="
sudo cat /var/log/openvpn/openvpn-status.log
EOF

chmod +x /home/ec2-user/openvpn-status.sh
chown ec2-user:ec2-user /home/ec2-user/openvpn-status.sh

# 안내 메시지 출력
echo -e "\n${GREEN}OpenVPN 설치가 완료되었습니다!${NC}"
echo -e "${YELLOW}상태 확인:${NC} systemctl status openvpn@server"
echo -e "${YELLOW}클라이언트 구성 파일:${NC} /home/ec2-user/$CLIENT_NAME.ovpn"
echo -e "${YELLOW}새 클라이언트 생성:${NC} /home/ec2-user/create-client.sh <클라이언트_이름>"
echo -e "${YELLOW}상태 확인 스크립트:${NC} /home/ec2-user/openvpn-status.sh"

echo -e "\n${GREEN}클라이언트 구성 파일을 다운로드하여 OpenVPN Connect 앱에서 사용하세요:${NC}"
echo -e "로컬 컴퓨터에서: scp -i your-key.pem ec2-user@$SERVER_IP:/home/ec2-user/$CLIENT_NAME.ovpn ."