#!/bin/bash

# Create bridge network for VM to access 192.168.0.x network

set -e

echo "🌉 Setting up bridge network for Proxmox VM..."

# Create bridge network XML configuration
cat > /tmp/br0.xml << EOF
<network>
  <name>br0</name>
  <forward mode='bridge'/>
  <bridge name='br0'/>
</network>
EOF

# Define and start the bridge network
sudo virsh net-define /tmp/br0.xml
sudo virsh net-start br0
sudo virsh net-autostart br0

echo "✅ Bridge network br0 created and started"

# Create bridge interface using systemd-networkd
sudo tee /etc/systemd/network/br0.netdev > /dev/null << EOF
[NetDev]
Name=br0
Kind=bridge
EOF

sudo tee /etc/systemd/network/br0.network > /dev/null << EOF
[Match]
Name=br0

[Network]
DHCP=yes
IPForward=yes
EOF

sudo tee /etc/systemd/network/enp4s0.network > /dev/null << EOF
[Match]
Name=enp4s0

[Network]
Bridge=br0
EOF

echo "🔧 Network configuration created. To apply:"
echo "   sudo systemctl enable systemd-networkd"
echo "   sudo systemctl restart systemd-networkd"
echo ""
echo "💡 Alternative: Use existing virbr0 with NAT and port forwarding"
