#!/bin/bash

# Simplified Proxmox VE VM Creation Script
# Uses user session and home directory storage

set -e

VM_NAME="proxmox-selfhost"
VM_IP="192.168.0.65"
CLUSTER_IP="192.168.0.64"
ISO_PATH="/home/lou/Downloads/proxmox-ve-8.3-1.iso"
VM_DIR="$HOME/VMs"
DISK_SIZE="100G"
RAM="8192"  # 8GB RAM
VCPUS="4"   # 4 vCPUs

echo "🚀 Creating Proxmox VE VM for self-hosting..."

# Create VM directory
mkdir -p "$VM_DIR"

echo "💾 Creating VM with the following specs:"
echo "   Name: $VM_NAME"
echo "   IP: $VM_IP (will join cluster at $CLUSTER_IP)"
echo "   RAM: ${RAM}MB"
echo "   CPUs: $VCPUS"
echo "   Disk: $DISK_SIZE"
echo "   Storage: $VM_DIR"
echo "   ISO: $ISO_PATH"

# Create disk image first
echo "📀 Creating disk image..."
qemu-img create -f qcow2 "$VM_DIR/${VM_NAME}.qcow2" 100G

# Create the VM using virt-install with user session
echo "🖥️ Creating virtual machine..."
virt-install \
    --connect qemu:///session \
    --name="$VM_NAME" \
    --ram="$RAM" \
    --vcpus="$VCPUS" \
    --cpu host-model \
    --hvm \
    --arch x86_64 \
    --disk path="$VM_DIR/${VM_NAME}.qcow2",format=qcow2,bus=virtio \
    --cdrom="$ISO_PATH" \
    --network network=default,model=virtio \
    --graphics vnc,listen=127.0.0.1,port=5901 \
    --video=cirrus \
    --os-variant=debian11 \
    --boot cdrom,hd \
    --console pty,target_type=serial \
    --noautoconsole

echo "✅ VM '$VM_NAME' created successfully!"
echo ""
echo "🖥️  VM Management (user session):"
echo "   VNC Access: vnc://localhost:5901"
echo "   Console: virsh --connect qemu:///session console $VM_NAME"
echo "   Start: virsh --connect qemu:///session start $VM_NAME"
echo "   Stop: virsh --connect qemu:///session shutdown $VM_NAME"
echo "   List: virsh --connect qemu:///session list --all"
echo ""
echo "📋 Next steps:"
echo "1. Connect via VNC (vnc://localhost:5901) to complete Proxmox installation"
echo "2. During installation, configure network:"
echo "   - IP: $VM_IP"
echo "   - Gateway: 192.168.0.1"
echo "   - DNS: 192.168.0.1"
echo "   - Hostname: proxmox-selfhost"
echo "3. After installation, access web interface at https://$VM_IP:8006"
echo "4. Join cluster at $CLUSTER_IP"
echo ""
echo "🔧 VM will initially get NAT IP, you'll need to:"
echo "   - Install Proxmox VE"
echo "   - Configure static IP $VM_IP in the VM"
echo "   - Or set up port forwarding for testing"
