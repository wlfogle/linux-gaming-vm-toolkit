#!/bin/bash

echo "🚀 Proxmox VE Post-Install Beast Mode Configuration"
echo "=================================================="

# This script should be run INSIDE the Proxmox VM after installation
# Copy this to the Proxmox VM and run it there

# Disable enterprise repository and add no-subscription repo
echo "📦 Configuring repositories..."
sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list 2>/dev/null || true
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

# Add Proxmox repository key
wget -qO- https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg

# Update packages
echo "🔄 Updating system packages..."
apt update && apt dist-upgrade -y

# Install useful packages
echo "📦 Installing additional packages..."
apt install -y \
    htop \
    iotop \
    iftop \
    ncdu \
    tree \
    curl \
    wget \
    vim \
    git \
    screen \
    tmux \
    intel-microcode \
    qemu-guest-agent

# Enable and start QEMU guest agent
echo "🔧 Enabling QEMU guest agent..."
systemctl enable qemu-guest-agent
systemctl start qemu-guest-agent

# Configure CPU governor for performance
echo "⚡ Setting CPU to performance mode..."
echo 'GOVERNOR="performance"' > /etc/default/cpufrequtils
systemctl enable cpufrequtils || true

# Optimize kernel parameters for virtualization
echo "🔧 Optimizing kernel parameters..."
cat >> /etc/sysctl.conf << EOF

# Proxmox beast mode optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_max_backlog = 5000
vm.swappiness = 1
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
kernel.numa_balancing = 0
EOF

# Configure logrotate to prevent log growth
echo "📋 Configuring log rotation..."
cat > /etc/logrotate.d/pve-firewall << EOF
/var/log/pve-firewall.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 root adm
}
EOF

# Set static IP (you'll need to configure this)
echo "🌐 Network configuration reminder:"
echo "   Configure static IP: 192.168.0.65/24"
echo "   Gateway: 192.168.0.1"
echo "   DNS: 192.168.0.1 or 8.8.8.8"

# Disable subscription nag (optional)
echo "🔧 Removing subscription nag..."
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service

# Configure firewall for cluster communication
echo "🔥 Configuring firewall for cluster..."
ufw allow 22/tcp    # SSH
ufw allow 8006/tcp  # Proxmox web interface
ufw allow 5405:5412/udp  # Corosync cluster
ufw allow 3128/tcp  # Proxmox backup

echo "✅ Post-install configuration complete!"
echo ""
echo "🎯 Next steps:"
echo "   1. Access web interface: https://$(hostname -I | awk '{print $1}'):8006"
echo "   2. Install ProxmenUX: bash <(curl -s https://raw.githubusercontent.com/aaronksaunders/proxmenux/main/install.sh)"
echo "   3. Join cluster: pvecm add 192.168.0.64"
echo ""
echo "🏠 Your beast Proxmox node is ready with:"
echo "   - 32GB RAM"
echo "   - 16 CPU cores"
echo "   - 200GB storage"
echo "   - Performance optimizations"
echo "   - No subscription restrictions"
