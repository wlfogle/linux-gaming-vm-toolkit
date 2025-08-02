#!/bin/bash

# Setup SSH access to Proxmox VM
# Run this after the VM has IP 192.168.0.65

set -e

PROXMOX_VM_IP="192.168.0.65"

echo "🔑 Setting up SSH access to Proxmox VM"
echo "======================================"

echo "📡 Testing connectivity to $PROXMOX_VM_IP..."
if ping -c 2 "$PROXMOX_VM_IP" >/dev/null 2>&1; then
    echo "✅ VM is reachable at $PROXMOX_VM_IP"
else
    echo "❌ VM not reachable at $PROXMOX_VM_IP"
    echo "   Make sure the VM has been configured with static IP"
    echo "   Current VM status:"
    sudo virsh list --all | grep proxmox-selfhost
    echo ""
    echo "   Try getting current IP:"
    sudo virsh domifaddr proxmox-selfhost
    exit 1
fi

echo ""
echo "🔑 Copying SSH key to Proxmox VM..."
if ssh-copy-id proxmox; then
    echo "✅ SSH key copied successfully"
else
    echo "❌ Failed to copy SSH key"
    echo "   Make sure SSH is enabled in the VM"
    echo "   You may need to enable it manually first"
    exit 1
fi

echo ""
echo "🧪 Testing SSH connection..."
if ssh proxmox "hostname && pveversion"; then
    echo "✅ SSH connection successful!"
else
    echo "❌ SSH connection failed"
    exit 1
fi

echo ""
echo "✅ SSH setup complete!"
echo ""
echo "📋 Available SSH commands:"
echo "   ssh pimox     # Connect to Raspberry Pi Proxmox (.64)"
echo "   ssh proxmox   # Connect to VM Proxmox (.65)"
echo ""
echo "🌐 Web interfaces:"
echo "   pimox-web     # Open https://192.168.0.64:8006"
echo "   proxmox-web   # Open https://192.168.0.65:8006"
