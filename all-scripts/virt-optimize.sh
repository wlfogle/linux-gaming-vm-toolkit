#!/bin/bash

# System Optimization for Virtualization and Containerization
# For use with Garuda Linux on high-performance hardware

set -e

echo "🚀 Optimizing system for virtualization and containerization..."

# CPU Governor optimization for performance
echo "⚡ Setting CPU governor to performance..."
if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [ -w "$cpu" ]; then
            echo performance | sudo tee "$cpu" > /dev/null
        fi
    done
fi

# Optimize VM dirty ratio for large memory systems
echo "💾 Optimizing memory management for VMs..."
echo 'vm.dirty_ratio = 5' | sudo tee -a /etc/sysctl.d/99-virt.conf
echo 'vm.dirty_background_ratio = 2' | sudo tee -a /etc/sysctl.d/99-virt.conf
echo 'vm.vfs_cache_pressure = 50' | sudo tee -a /etc/sysctl.d/99-virt.conf

# Network optimizations for virtualization
echo "🌐 Optimizing network for VM/container traffic..."
echo 'net.core.rmem_max = 134217728' | sudo tee -a /etc/sysctl.d/99-virt.conf
echo 'net.core.wmem_max = 134217728' | sudo tee -a /etc/sysctl.d/99-virt.conf
echo 'net.ipv4.tcp_rmem = 4096 87380 134217728' | sudo tee -a /etc/sysctl.d/99-virt.conf
echo 'net.ipv4.tcp_wmem = 4096 65536 134217728' | sudo tee -a /etc/sysctl.d/99-virt.conf
echo 'net.core.netdev_max_backlog = 5000' | sudo tee -a /etc/sysctl.d/99-virt.conf

# Enable KSM (Kernel Same-page Merging) for memory deduplication
echo "🔗 Enabling Kernel Same-page Merging for memory efficiency..."
echo 1 | sudo tee /sys/kernel/mm/ksm/run
echo 'echo 1 > /sys/kernel/mm/ksm/run' | sudo tee /etc/tmpfiles.d/ksm.conf

# Optimize I/O scheduler for SSD (if detected)
echo "💿 Optimizing I/O scheduler..."
for disk in /sys/block/sd* /sys/block/nvme*; do
    if [ -d "$disk" ]; then
        if [[ $(cat $disk/queue/rotational) == "0" ]]; then
            echo "mq-deadline" | sudo tee $disk/queue/scheduler > /dev/null
            echo "Setting mq-deadline for SSD: $(basename $disk)"
        fi
    fi
done

# Apply sysctl settings
sudo sysctl -p /etc/sysctl.d/99-virt.conf

# Enable and configure zram if available
echo "🗜️ Configuring zram compression..."
if [ -f /etc/systemd/zram-generator.conf ]; then
    sudo bash -c 'cat > /etc/systemd/zram-generator.conf << EOF
[zram0]
zram-fraction = 0.1
max-zram-size = 8192
compression-algorithm = zstd
EOF'
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true
fi

# Create VM storage directory with proper permissions
echo "📁 Setting up VM storage directory..."
sudo mkdir -p /var/lib/libvirt/images
sudo chmod 755 /var/lib/libvirt/images
sudo chown libvirt-qemu:libvirt-qemu /var/lib/libvirt/images

# Configure libvirt default network
echo "🌉 Configuring libvirt networking..."
sudo virsh net-autostart default || true
sudo virsh net-start default 2>/dev/null || true

# Set up container registries
echo "🐳 Configuring container registries..."
mkdir -p ~/.config/containers
cat > ~/.config/containers/registries.conf << 'EOF'
[registries.search]
registries = ["docker.io", "registry.fedoraproject.org", "registry.access.redhat.com", "registry.centos.org", "quay.io"]

[registries.insecure]
registries = []

[registries.block]
registries = []
EOF

# Install some useful container images
echo "📦 Pre-pulling useful container images..."
docker pull alpine:latest &
docker pull ubuntu:latest &
docker pull fedora:latest &
podman pull alpine:latest &
podman pull ubuntu:latest &
podman pull fedora:latest &
wait

echo "✅ System optimization complete!"
echo ""
echo "📋 Summary of optimizations applied:"
echo "   • CPU governor set to performance"
echo "   • Memory management tuned for VMs"
echo "   • Network stack optimized"
echo "   • KSM enabled for memory deduplication"
echo "   • I/O scheduler optimized for SSDs"
echo "   • Zram compression configured"
echo "   • LibVirt storage and networking configured"
echo "   • Container registries configured"
echo "   • Base container images pre-pulled"
echo ""
echo "🔄 Please reboot or log out/in for all changes to take effect."
echo "🔧 Your system is now optimized for virtualization and containerization!"
