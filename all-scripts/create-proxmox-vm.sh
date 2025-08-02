#!/bin/bash

# Proxmox VE VM Creation Script for Self-Hosting
# This creates a VM that will join cluster at 192.168.0.64

set -e

VM_NAME="proxmox-selfhost"
VM_IP="192.168.0.65"
CLUSTER_IP="192.168.0.64"
ISO_PATH="/home/lou/Downloads/proxmox-ve-8.3-1.iso"
DISK_SIZE="100G"
RAM="8192"  # 8GB RAM
VCPUS="4"   # 4 vCPUs

echo "🚀 Creating Proxmox VE VM for self-hosting..."

# Ensure libvirt is running
sudo systemctl start libvirtd

# Create VM storage directory if it doesn't exist
sudo mkdir -p /var/lib/libvirt/images

# Fix permissions for libvirt images directory
sudo chown -R libvirt-qemu:libvirt-qemu /var/lib/libvirt/images
sudo chmod 755 /var/lib/libvirt/images

echo "💾 Creating VM with the following specs:"
echo "   Name: $VM_NAME"
echo "   IP: $VM_IP (will join cluster at $CLUSTER_IP)"
echo "   RAM: ${RAM}MB"
echo "   CPUs: $VCPUS"
echo "   Disk: $DISK_SIZE"
echo "   ISO: $ISO_PATH"

# Create the VM
virt-install \
    --name="$VM_NAME" \
    --ram="$RAM" \
    --vcpus="$VCPUS" \
    --cpu host \
    --hvm \
    --arch x86_64 \
    --disk path="/var/lib/libvirt/images/${VM_NAME}.qcow2",size=100,format=qcow2,bus=virtio \
    --cdrom="$ISO_PATH" \
    --network type=direct,source=enp4s0,source_mode=bridge,model=virtio \
    --graphics vnc,listen=0.0.0.0,port=5900 \
    --video=cirrus \
    --os-variant=debian11 \
    --boot cdrom,hd \
    --console pty,target_type=serial \
    --noautoconsole \
    --wait=-1

echo "✅ VM '$VM_NAME' created successfully!"
echo ""
echo "🖥️  VM Management:"
echo "   VNC Access: vnc://localhost:5900"
echo "   Console: virsh console $VM_NAME"
echo "   Start: virsh start $VM_NAME"
echo "   Stop: virsh shutdown $VM_NAME"
echo ""
echo "📋 Next steps:"
echo "1. Connect via VNC (vnc://localhost:5900) to complete Proxmox installation"
echo "2. During installation, set IP to $VM_IP"
echo "3. After installation, join cluster at $CLUSTER_IP"
echo ""
echo "🔧 Installation Notes:"
echo "   - Use static IP: $VM_IP"
echo "   - Gateway: 192.168.0.1"
echo "   - DNS: 192.168.0.1 or 8.8.8.8"
echo "   - Hostname: proxmox-selfhost"
echo "   - Domain: local"
