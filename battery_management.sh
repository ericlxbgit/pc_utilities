#!/bin/bash
# update-tlp-charge: install TLP if needed and update charge thresholds

CONFIG="/etc/tlp.conf"
BACKUP="/etc/tlp.conf.bak.$(date +%F_%T)"

START="$1"
STOP="$2"

# -----------------------
# 1. Check parameters
# -----------------------
if [[ -z "$START" || -z "$STOP" ]]; then
    echo "Usage: sudo update-tlp-charge <start_threshold> <stop_threshold>"
    exit 1
fi

# -----------------------
# 2. Ensure TLP packages are installed
# -----------------------
echo "Checking TLP installation..."
if ! dpkg -s tlp &> /dev/null; then
    echo "Installing tlp and tlp-rdw..."
    apt update
    apt install -y tlp tlp-rdw
else
    echo "TLP already installed."
fi

# -----------------------
# 3. Ensure config file exists
# -----------------------
if [[ ! -f "$CONFIG" ]]; then
    echo "TLP config not found, creating default..."
    cp /usr/share/tlp/tlp.conf "$CONFIG"
fi

# -----------------------
# 4. Backup config
# -----------------------
echo "Backing up $CONFIG to $BACKUP"
cp "$CONFIG" "$BACKUP"

# -----------------------
# 5. Remove old threshold settings
# -----------------------
sed -i '/START_CHARGE_THRESH_/d' "$CONFIG"
sed -i '/STOP_CHARGE_THRESH_/d' "$CONFIG"

# -----------------------
# 6. Write new values
# -----------------------
cat <<EOF >> "$CONFIG"

# Added automatically by update-tlp-charge
START_CHARGE_THRESH_BAT0=$START
STOP_CHARGE_THRESH_BAT0=$STOP
EOF

echo "Updated charge thresholds to:"
echo "  Start = $START%"
echo "  Stop  = $STOP%"

# -----------------------
# 7. Apply changes
# -----------------------
echo "Applying TLP settings..."
systemctl restart tlp || tlp start

echo "Done."
