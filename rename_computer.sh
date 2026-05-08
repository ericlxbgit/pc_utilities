#!/bin/bash

# rename-computer.sh - Rename your Linux Mint system hostname safely

set -e  # Exit on any error

echo "=== Linux Mint Computer Renamer ==="
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root. Use: sudo ./rename-computer.sh"
   exit 1
fi

# Get current hostname
CURRENT_HOSTNAME=$(hostname)
echo "Current hostname: $CURRENT_HOSTNAME"
echo

# Prompt for new hostname
read -p "Enter new hostname (no spaces, only letters, digits, hyphens): " NEW_HOSTNAME

# Validate hostname (basic check)
if [[ -z "$NEW_HOSTNAME" ]]; then
    echo "❌ Error: Hostname cannot be empty."
    exit 1
fi

if [[ ! "$NEW_HOSTNAME" =~ ^[a-zA-Z0-9\-]+$ ]]; then
    echo "❌ Error: Hostname must contain only letters, digits, and hyphens."
    exit 1
fi

if [[ ${#NEW_HOSTNAME} -gt 63 ]]; then
    echo "❌ Error: Hostname cannot exceed 63 characters."
    exit 1
fi

# Update /etc/hostname
echo "🔄 Updating /etc/hostname..."
echo "$NEW_HOSTNAME" > /etc/hostname

# Update /etc/hosts (replace old hostname with new one, preserve localhost line)
echo "🔄 Updating /etc/hosts..."
sed -i "s/$CURRENT_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts

# Optional: Ensure localhost line is correct
if ! grep -q "^127.0.1.1.*$NEW_HOSTNAME" /etc/hosts; then
    sed -i "s/^127.0.1.1.*/127.0.1.1\t$NEW_HOSTNAME/" /etc/hosts
fi

# Restart systemd-hostnamed service to apply immediately
echo "🔁 Restarting hostname service..."
systemctl restart systemd-hostnamed

# Optional: Show result
echo
echo "✅ Success! Hostname changed from:"
echo "   OLD: $CURRENT_HOSTNAME"
echo "   NEW: $NEW_HOSTNAME"
echo
echo "💡 Tip: Log out and log back in (or restart) for full effect in terminal and GUI."
echo "   To verify now, run: hostname"