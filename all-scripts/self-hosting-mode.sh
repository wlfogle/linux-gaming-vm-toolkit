#!/bin/bash

echo "🏠 Switching to Self-Hosting Beast Mode..."

# Check if gaming VM is running
if sudo virsh list --state-running | grep -q win10-gaming; then
    echo "🎮 Gaming VM detected - using hybrid mode"
    GAMING_ACTIVE=true
else
    echo "🏠 Pure self-hosting mode - maximum resources"
    GAMING_ACTIVE=false
fi

# Stop current Proxmox VM to reconfigure
if sudo virsh list --state-running | grep -q proxmox-selfhost; then
    echo "⏹️ Stopping current Proxmox VM..."
    sudo virsh shutdown proxmox-selfhost
    sleep 5
fi

# Create optimized Proxmox configuration based on mode
if [ "$GAMING_ACTIVE" = false ]; then
    # Pure self-hosting mode - 32GB RAM, 14 cores
    echo "🚀 Configuring Proxmox for MAXIMUM self-hosting power..."
    PROXMOX_RAM="33554432"  # 32GB
    PROXMOX_VCPUS="14"
    CORE_RANGE="2-15"
    echo "   - 32GB RAM dedicated"
    echo "   - 14 CPU cores (cores 2-15)"
else
    # Hybrid mode - 20GB RAM, 6 cores  
    echo "🎯 Configuring Proxmox for hybrid gaming + self-hosting..."
    PROXMOX_RAM="20971520"  # 20GB
    PROXMOX_VCPUS="6"
    CORE_RANGE="10-15"
    echo "   - 20GB RAM dedicated"
    echo "   - 6 CPU cores (cores 10-15)"
fi

# Update Proxmox VM memory and CPU
sudo virsh setmaxmem proxmox-selfhost ${PROXMOX_RAM}k --config
sudo virsh setmem proxmox-selfhost ${PROXMOX_RAM}k --config
sudo virsh setvcpus proxmox-selfhost $PROXMOX_VCPUS --config --maximum
sudo virsh setvcpus proxmox-selfhost $PROXMOX_VCPUS --config

echo "⚡ Setting CPU performance mode..."
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null

echo "🚀 Starting optimized Proxmox VM..."
sudo virsh start proxmox-selfhost

echo "✅ Self-hosting mode activated!"
echo ""
echo "🏠 Your self-hosting setup can now run:"
echo "   - Proxmox with $PROXMOX_VCPUS cores and $(($PROXMOX_RAM/1024/1024))GB RAM"
echo "   - Multiple Docker containers"
echo "   - Kubernetes clusters"
echo "   - Database servers"
echo "   - Web services"
echo "   - Home automation"
echo "   - Media servers (Plex/Jellyfin)"
echo "   - Cloud storage (Nextcloud)"
echo "   - VPN servers"
echo "   - Monitoring stacks"
echo "   - And much more!"
echo ""
echo "🔧 Access Proxmox web interface at: https://proxmox-vm-ip:8006"
echo "🎯 This beast can handle ANY self-hosting workload!"

if [ "$GAMING_ACTIVE" = true ]; then
    echo ""
    echo "🎮 Gaming VM is also running - you have BOTH gaming and self-hosting!"
    echo "   Your system is running like a DATACENTER! 🔥"
fi
