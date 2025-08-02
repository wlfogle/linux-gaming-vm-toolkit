#!/bin/bash

# Post-installation configuration for Proxmox VM
# Run this after Proxmox VE is installed in the VM

set -e

VM_NAME="proxmox-selfhost"
TARGET_IP="192.168.0.65"
CLUSTER_IP="192.168.0.64"

echo "🔧 Proxmox VM Post-Installation Configuration"
echo "=============================================="

echo "📋 Current VM Status:"
sudo virsh list --all | grep "$VM_NAME"

echo ""
echo "🌐 Network Configuration Steps:"
echo "1. Get current VM IP:"
sudo virsh domifaddr "$VM_NAME" 2>/dev/null || echo "   VM IP not available yet (may need DHCP lease)"

echo ""
echo "🔗 Cluster Setup Instructions:"
echo "==============================================="
echo ""
echo "After Proxmox VE installation is complete:"
echo ""
echo "1. 📡 Configure VM Network for cluster access:"
echo "   - Edit /etc/network/interfaces in the VM"
echo "   - Change from DHCP to static IP $TARGET_IP"
echo "   - Gateway: 192.168.0.1"
echo "   - DNS: 192.168.0.1"
echo ""
echo "2. 🏗️  Create cluster on master node ($CLUSTER_IP):"
echo "   SSH to root@$CLUSTER_IP and run:"
echo "   pvecm create my-cluster"
echo ""
echo "3. 🔗 Join VM to cluster:"
echo "   In the VM (after network reconfiguration):"
echo "   pvecm add $CLUSTER_IP"
echo ""
echo "4. ✅ Verify cluster:"
echo "   pvecm status"
echo "   pvecm nodes"
echo ""
echo "🖥️  VM Management Commands:"
echo "   VNC: vnc://localhost:5902"
echo "   Console: sudo virsh console $VM_NAME"
echo "   Shutdown: sudo virsh shutdown $VM_NAME"
echo "   Destroy: sudo virsh destroy $VM_NAME"
echo "   Start: sudo virsh start $VM_NAME"
