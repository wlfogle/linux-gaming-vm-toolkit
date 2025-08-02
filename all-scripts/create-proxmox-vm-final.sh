#!/bin/bash

# Final Proxmox VE VM Creation Script
# Uses system libvirt with proper permissions

set -e

VM_NAME="proxmox-selfhost"
VM_IP="192.168.0.65"
CLUSTER_IP="192.168.0.64"
ISO_PATH="/var/lib/libvirt/images/iso/proxmox-ve-8.3-1.iso"
DISK_SIZE="100G"
RAM="8192"  # 8GB RAM
VCPUS="4"   # 4 vCPUs

echo "🚀 Creating Proxmox VE VM for self-hosting..."

# Ensure libvirt is running and default network is active
sudo systemctl start libvirtd
sudo virsh net-start default 2>/dev/null || true

# Set up proper permissions
sudo mkdir -p /var/lib/libvirt/images
sudo chown -R libvirt-qemu:libvirt-qemu /var/lib/libvirt/images
sudo chmod 755 /var/lib/libvirt/images

echo "💾 Creating VM with the following specs:"
echo "   Name: $VM_NAME"
echo "   Target IP: $VM_IP (will join cluster at $CLUSTER_IP)"
echo "   RAM: ${RAM}MB"
echo "   CPUs: $VCPUS"
echo "   Disk: $DISK_SIZE"
echo "   ISO: $ISO_PATH"

# Create the VM using sudo virt-install
sudo virt-install \
    --name="$VM_NAME" \
    --ram="$RAM" \
    --vcpus="$VCPUS" \
    --cpu host-model \
    --hvm \
    --arch x86_64 \
    --disk path="/var/lib/libvirt/images/${VM_NAME}.qcow2",size=100,format=qcow2,bus=virtio \
    --cdrom="$ISO_PATH" \
    --network network=default,model=virtio \
    --graphics vnc,listen=0.0.0.0,port=5902 \
    --video=cirrus \
    --os-variant=debian11 \
    --boot cdrom,hd \
    --console pty,target_type=serial \
    --noautoconsole

echo "✅ VM '$VM_NAME' created successfully!"
echo ""
echo "🖥️  VM Management:"
echo "   VNC Access: vnc://localhost:5902"
echo "   Console: sudo virsh console $VM_NAME"
echo "   Start: sudo virsh start $VM_NAME"
echo "   Stop: sudo virsh shutdown $VM_NAME"
echo "   List: sudo virsh list --all"
echo ""
echo "🌐 Network Information:"
echo "   VM will get DHCP IP from 192.168.122.x range initially"
echo "   Default gateway: 192.168.122.1"
echo "   Access from host: via NAT on 192.168.122.x"
echo ""
echo "📋 Installation Steps:"
echo "1. Connect via VNC: vnc://localhost:5902"
echo "2. Install Proxmox VE using the installer"
echo "3. During network setup:"
echo "   - Accept DHCP initially or use static in 192.168.122.x range"
echo "   - Hostname: proxmox-selfhost"
echo "   - Domain: local"
echo "4. After installation, access via: https://VM_IP:8006"
echo ""
echo "🔗 Post-installation for cluster joining:"
echo "   After Proxmox is installed, configure bridged networking"
echo "   to get IP $VM_IP and join cluster at $CLUSTER_IP"
