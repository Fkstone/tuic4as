#!/bin/sh

set -e

# Error handling function
exit_on_error() {
  echo "❌ Installation failed, please check your environment or configuration." >&2
  exit 1
}

step() {
  echo
  echo "========== Step $1: $2 =========="
}

# Paths
CONFIG_DIR="/opt/etc/sing-box"
CERT_DIR="$CONFIG_DIR/cert"
LOG_FILE="/opt/var/log/sing-box.log"
INIT_SCRIPT="/opt/etc/init.d/S99sing-box"

# Step 1: Get user input
step 1 "Input port and domain strategy"
read -p "Enter TUIC service listen port (e.g., 22578): " PORT || exit_on_error

echo "Select domain strategy:"
echo "  1. prefer_ipv4"
echo "  2. prefer_ipv6"
read -p "Enter choice [1/2] (default 1): " IP_OPTION || exit_on_error
if [ "$IP_OPTION" = "2" ]; then
  DOMAIN_STRATEGY="prefer_ipv6"
else
  DOMAIN_STRATEGY="prefer_ipv4"
fi

# Step 2: Install sing-box
step 2 "Installing sing-box"
opkg update || exit_on_error
opkg install sing-box-go || exit_on_error

# Step 3: Create config and cert directories
step 3 "Creating configuration and certificate directories"
mkdir -p "$CERT_DIR" || exit_on_error

# Step 4: Generate ECC private key and self-signed certificate
step 4 "Generating ECC key and self-signed certificate"
openssl ecparam -genkey -name prime256v1 -out "$CERT_DIR/private.key" || exit_on_error
openssl req -new -x509 -days 3650 \
  -key "$CERT_DIR/private.key" \
  -out "$CERT_DIR/cert.pem" \
  -subj "/C=CN/ST=TUIC/L=Internet/O=Singbox/OU=TUIC/CN=example.com" || exit_on_error

# Step 5: Generate UUID and password
step 5 "Generating UUID and password"
UUID=$(sing-box generate uuid) || exit_on_error
PASSWORD=$(sing-box generate rand --base64 16) || exit_on_error

# Step 6: Write configuration file
step 6 "Writing configuration file"
cat > "$CONFIG_DIR/config.json" <<EOF
{
  "log": {
    "disabled": false,
    "level": "info",
    "timestamp": true,
    "output": "stdout"
  },
  "inbounds": [
    {
      "type": "tuic",
      "listen": "0.0.0.0",
      "listen_port": $PORT,
      "users": [
        {
          "uuid": "$UUID",
          "password": "$PASSWORD"
        }
      ],
      "congestion_control": "bbr",
      "zero_rtt_handshake": false,
      "tls": {
        "enabled": true,
        "alpn": [ "h3" ],
        "certificate_path": "$CERT_DIR/cert.pem",
        "key_path": "$CERT_DIR/private.key"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct",
      "domain_strategy": "$DOMAIN_STRATEGY"
    }
  ]
}
EOF

# Step 7: Create init script
step 7 "Creating init script"
cat > "$INIT_SCRIPT" <<EOF
#!/bin/sh
case "\$1" in
  start)
    echo "Starting sing-box..."
    /opt/bin/sing-box run -c "$CONFIG_DIR/config.json" >> "$LOG_FILE" 2>&1 &
    ;;
  stop)
    echo "Stopping sing-box..."
    killall sing-box
    ;;
  restart)
    \$0 stop
    sleep 1
    \$0 start
    ;;
  *)
    echo "Usage: \$0 {start|stop|restart}"
    exit 1
esac
exit 0
EOF

chmod +x "$INIT_SCRIPT" || exit_on_error
ln -sf "$INIT_SCRIPT" /opt/etc/rc.d/S99sing-box || exit_on_error

# Step 8: Start service immediately
step 8 "Starting sing-box service"
"$INIT_SCRIPT" start || exit_on_error

# Step 9: Add to services-start
step 9 "Registering to /jffs/scripts/services-start"
if ! grep -q "$INIT_SCRIPT start" /jffs/scripts/services-start; then
  echo "$INIT_SCRIPT start" >> /jffs/scripts/services-start || exit_on_error
  echo "Added to /jffs/scripts/services-start"
else
  echo "Start command already exists in /jffs/scripts/services-start"
fi

# Step 10: Show TUIC link
step 10 "Generating TUIC link"

TUIC_IP="192.168.50.1"
LINK="tuic://$UUID:$PASSWORD@$TUIC_IP:$PORT?congestion_control=bbr&alpn=h3&udp_relay_mode=native&allow_insecure=1&disable_sni=1#tuic_singbox"

echo
echo "✅ Installation successful! Your TUIC link (for Nekobox etc.):"
echo "$LINK"
echo
