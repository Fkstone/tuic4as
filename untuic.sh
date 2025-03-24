#!/bin/sh

echo
echo "========== Uninstalling sing-box (TUIC) =========="

CONFIG_DIR="/opt/etc/sing-box"
INIT_SCRIPT="/opt/etc/init.d/S99sing-box"
RC_LINK="/opt/etc/rc.d/S99sing-box"
LOG_FILE="/opt/var/log/sing-box.log"
SERVICE_START="/jffs/scripts/services-start"

# Step 1: Stop sing-box if running
echo "🔄 Stopping sing-box if running..."
killall sing-box 2>/dev/null

# Step 2: Remove init script and rc.d link
echo "🧹 Removing init script..."
[ -f "$INIT_SCRIPT" ] && rm -f "$INIT_SCRIPT"
[ -L "$RC_LINK" ] && rm -f "$RC_LINK"

# Step 3: Remove configuration and certs
echo "🧼 Removing configuration and certificates..."
[ -d "$CONFIG_DIR" ] && rm -rf "$CONFIG_DIR"

# Step 4: Remove log file
echo "🗑 Removing log file..."
[ -f "$LOG_FILE" ] && rm -f "$LOG_FILE"

# Step 5: Remove startup line from /jffs/scripts/services-start
echo "✂ Cleaning up services-start..."
if [ -f "$SERVICE_START" ]; then
  sed -i '/S99sing-box start/d' "$SERVICE_START"
fi

# Step 6: Remove installed package (optional)
echo "📦 Uninstalling sing-box-go package..."
opkg remove sing-box-go 2>/dev/null

echo
echo "✅ sing-box has been fully uninstalled."
