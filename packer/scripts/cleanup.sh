#!/bin/bash
# Cleanup script to reduce VM image size
# Removes temporary files, caches, and logs

set -e

echo "========================================="
echo "Cleaning up VM image..."
echo "========================================="

# Clean apt cache
echo "🧹 Cleaning apt cache..."
apt-get clean
apt-get autoclean
apt-get autoremove -y

# Remove old kernels (keep current)
echo "🧹 Removing old kernels..."
dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs apt-get -y purge || true

# Clear logs
echo "🧹 Clearing logs..."
find /var/log -type f -exec truncate -s 0 {} \;
rm -rf /var/log/*.gz
rm -rf /var/log/*.1
rm -rf /var/log/*/*.gz
rm -rf /var/log/*/*.1

# Clear tmp directories
echo "🧹 Clearing tmp directories..."
rm -rf /tmp/*
rm -rf /var/tmp/*

# Clear bash history
echo "🧹 Clearing bash history..."
history -c
cat /dev/null > ~/.bash_history
cat /dev/null > /home/sentinelcore/.bash_history

# Clear SSH host keys (will be regenerated on first boot)
echo "🧹 Removing SSH host keys..."
rm -f /etc/ssh/ssh_host_*

# Create script to regenerate SSH keys on first boot
cat > /etc/rc.local << 'EOF'
#!/bin/bash
# Regenerate SSH host keys on first boot
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi
exit 0
EOF
chmod +x /etc/rc.local

# Clear machine-id (will be regenerated)
echo "🧹 Clearing machine-id..."
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

# Remove cloud-init artifacts
echo "🧹 Cleaning cloud-init..."
rm -rf /var/lib/cloud/*

# Clear DHCP leases
echo "🧹 Clearing DHCP leases..."
rm -f /var/lib/dhcp/*

# Clear udev rules
echo "🧹 Clearing udev persistent rules..."
rm -f /etc/udev/rules.d/70-persistent-net.rules

# Remove build artifacts and caches
echo "🧹 Removing build caches..."
rm -rf /opt/sentinelcore/vulnerability-manager/target/debug
rm -rf /opt/sentinelcore/vulnerability-manager/target/release/.fingerprint
rm -rf /opt/sentinelcore/vulnerability-manager-frontend/node_modules/.cache
rm -rf /root/.cargo/registry/cache
rm -rf /home/sentinelcore/.cargo/registry/cache

# Remove git history to save space (optional - keep for updates)
# cd /opt/sentinelcore && git gc --aggressive --prune=all

# Zero out free space to improve compression
echo "🧹 Zeroing free space (this may take a while)..."
dd if=/dev/zero of=/EMPTY bs=1M 2>/dev/null || true
rm -f /EMPTY

# Sync filesystem
sync

echo "========================================="
echo "✅ Cleanup complete"
echo "========================================="
