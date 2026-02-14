bash <<'EOF'
set -e

echo "=== Updating system ==="
apt update -y
apt install -y curl unzip jq openssl ufw

echo "=== Installing sing-box ==="
VERSION=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | jq -r .tag_name)
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
  ARCH="amd64"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
  ARCH="arm64"
else
  echo "Unsupported arch"
  exit 1
fi

curl -Lo sing-box.tar.gz https://github.com/SagerNet/sing-box/releases/download/${VERSION}/sing-box-${VERSION#v}-linux-${ARCH}.tar.gz
tar -xzf sing-box.tar.gz
install -m 755 sing-box-*/sing-box /usr/local/bin/sing-box
rm -rf sing-box*

echo "=== Generating credentials ==="
UUID=$(cat /proc/sys/kernel/random/uuid)
HY2_PASS=$(openssl rand -hex 16)

KEYPAIR=$(sing-box generate reality-keypair)
PRIVATE_KEY=$(echo "$KEYPAIR" | grep PrivateKey | awk '{print $2}')
PUBLIC_KEY=$(echo "$KEYPAIR" | grep PublicKey | awk '{print $2}')
SHORT_ID=$(openssl rand -hex 8)

echo "=== Creating config ==="
mkdir -p /etc/sing-box

cat > /etc/sing-box/config.json <<CONFIG
{
  "log": { "level": "info", "timestamp": true },

  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-reality",
      "listen": "::",
      "listen_port": 8443,
      "users": [
        { "uuid": "$UUID", "flow": "xtls-rprx-vision" }
      ],
      "tls": {
        "enabled": true,
        "server_name": "www.microsoft.com",
        "reality": {
          "enabled": true,
          "handshake": { "server": "www.microsoft.com", "server_port": 443 },
          "private_key": "$PRIVATE_KEY",
          "short_id": ["$SHORT_ID"]
        }
      }
    },
    {
      "type": "hysteria2",
      "tag": "hy2",
      "listen": "::",
      "listen_port": 2102,
      "users": [
        { "password": "$HY2_PASS" }
      ],
      "tls": {
        "enabled": true,
        "alpn": ["h3"],
        "certificate_path": "/etc/sing-box/self.crt",
        "key_path": "/etc/sing-box/self.key"
      }
    }
  ],
  "outbounds": [
    { "type": "direct" }
  ]
}
CONFIG

echo "=== Creating self-signed cert for HY2 ==="
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout /etc/sing-box/self.key \
  -out /etc/sing-box/self.crt \
  -days 3650 \
  -subj "/CN=www.bing.com"

echo "=== Creating systemd service ==="
cat > /etc/systemd/system/sing-box.service <<SERVICE
[Unit]
Description=sing-box
After=network.target

[Service]
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable sing-box
systemctl restart sing-box

echo "=== Opening firewall ==="
ufw allow 22/tcp
ufw allow 8443/tcp
ufw allow 2102/udp
ufw --force enable

IPV4=$(curl -4 -s ifconfig.me)
IPV6=$(curl -6 -s ifconfig.me || echo "No IPv6")

echo
echo "==================== DONE ===================="
echo "IPv4: $IPV4"
echo "IPv6: $IPV6"
echo
echo "[VLESS + Reality]"
echo "Address: use IPv4 or IPv6"
echo "Port: 8443"
echo "UUID: $UUID"
echo "Flow: xtls-rprx-vision"
echo "SNI: www.microsoft.com"
echo "Reality PublicKey: $PUBLIC_KEY"
echo "ShortID: $SHORT_ID"
echo
echo "[Hysteria2]"
echo "Address: use IPv4 or IPv6"
echo "Port: 2102"
echo "Password: $HY2_PASS"
echo "TLS: self-signed (set insecure=true in client)"
echo "=============================================="
EOF

