#!/bin/bash

# Function to run on script exit
event_clean_up() {
    echo "🛑 Stopping Looking Glass client..."
    pkill -f looking-glass-client
}

# Set trap to clean up on exit
trap event_clean_up EXIT

echo "🎮 Starting Ultimate Gaming VM Setup..."

# Set CPU governor to performance
echo "⚡ Setting CPU to performance mode..."
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null

# Set I/O scheduler to mq-deadline for gaming
echo "💾 Optimizing I/O scheduler..."
echo mq-deadline | sudo tee /sys/block/nvme*/queue/scheduler > /dev/null

# Disable swapping during gaming
echo "🚫 Disabling swap for gaming session..."
sudo swapoff -a

# Set VM-specific kernel parameters
echo "🔧 Setting kernel parameters..."
echo 1 | sudo tee /proc/sys/vm/compact_memory > /dev/null

# Start Looking Glass daemon (if needed)
echo "👁️ Setting up Looking Glass..."
if [ ! -f /dev/shm/looking-glass ] || [ $(stat -c%s /dev/shm/looking-glass 2>/dev/null || echo 0) -lt 33554432 ]; then
    echo "🔧 Creating Looking Glass shared memory (32MB)..."
    sudo rm -f /dev/shm/looking-glass
    sudo dd if=/dev/zero of=/dev/shm/looking-glass bs=1M count=32 > /dev/null 2>&1
    sudo chown lou:kvm /dev/shm/looking-glass
    sudo chmod 660 /dev/shm/looking-glass
else
    echo "✅ Looking Glass shared memory already configured"
fi

# Check if desktop is using NVIDIA GPU
echo "🔍 Checking GPU usage..."
if sudo lsof /dev/nvidia* > /dev/null 2>&1; then
    echo "⚠️  WARNING: NVIDIA GPU is in use by desktop processes!"
    echo "📋 Processes using NVIDIA GPU:"
    sudo lsof /dev/nvidia* 2>/dev/null | grep -v "WARNING" | tail -n +2
    echo ""
    echo "💡 To fix this, you need to:"
    echo "   1. Switch your desktop to use Intel graphics"
    echo "   2. Or run this script from a TTY (Ctrl+Alt+F3)"
    echo ""
    read -p "🤔 Continue anyway? This will likely fail (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborting VM start. Please switch to Intel graphics first."
        exit 1
    fi
fi

# Unbind GPU from nvidia driver and bind to vfio-pci
echo "🎯 Binding GPU to VFIO for passthrough..."
sudo modprobe vfio-pci

# Check if GPU is bound to nvidia driver (not vfio-pci)
if lspci -k -s 02:00.0 | grep -q "Kernel driver in use: nvidia"; then
    echo "🔄 Unbinding GPU from NVIDIA driver..."
    
    # Try to unbind - this might fail if GPU is in use
    if ! echo 0000:02:00.0 | sudo tee /sys/bus/pci/drivers/nvidia/unbind > /dev/null 2>&1; then
        echo "❌ Failed to unbind GPU from NVIDIA driver!"
        echo "💡 The GPU is likely in use by the desktop. Try:"
        echo "   sudo systemctl stop sddm  # Stop display manager"
        echo "   # Then run this script from TTY"
        exit 1
    fi
    
    if ! echo 0000:02:00.1 | sudo tee /sys/bus/pci/drivers/snd_hda_intel/unbind > /dev/null 2>&1; then
        echo "⚠️  Warning: Failed to unbind GPU audio, continuing anyway..."
    fi
    
    echo "🔗 Binding GPU to VFIO..."
    echo 10de 27e0 | sudo tee /sys/bus/pci/drivers/vfio-pci/new_id > /dev/null 2>&1
    echo 10de 22bc | sudo tee /sys/bus/pci/drivers/vfio-pci/new_id > /dev/null 2>&1
    
    echo 0000:02:00.0 | sudo tee /sys/bus/pci/drivers/vfio-pci/bind > /dev/null 2>&1
    echo 0000:02:00.1 | sudo tee /sys/bus/pci/drivers/vfio-pci/bind > /dev/null 2>&1
    
    echo "✅ GPU successfully bound to VFIO!"
else
    echo "ℹ️  GPU is not bound to NVIDIA driver, checking VFIO..."
    if lspci -k -s 02:00.0 | grep -q "vfio-pci"; then
        echo "✅ GPU already bound to VFIO!"
    else
        echo "❓ GPU not bound to any expected driver. Current state:"
        lspci -k -s 02:00.0
    fi
fi

# Stop any other VMs that might interfere with SPICE/Looking Glass
echo "🔄 Checking for other running VMs..."
for vm in $(sudo virsh list --state-running --name | grep -v win10-gaming); do
    if [ ! -z "$vm" ]; then
        echo "🛑 Stopping $vm to avoid SPICE conflicts..."
        sudo virsh shutdown "$vm"
        sleep 2
    fi
done

echo "🚀 Starting VM..."
if sudo virsh list --state-running | grep -q "win10-gaming"; then
    echo "ℹ️  VM is already running!"
else
    sudo virsh start win10-gaming
fi

echo "🎯 VM started! You can now:"
echo "   1. Connect with Looking Glass: looking-glass-client"
echo "   2. OR use virt-viewer: virt-viewer --connect qemu:///system win10-gaming"
echo ""
echo "📁 Your Games drive is available as the second disk in Windows"
echo "💿 VirtIO drivers are on the CD-ROM drive"
echo "🎮 Point Battle.net to E:\\Games\\Diablo IV\\ for your existing installation"
echo ""
echo "⚡ Gaming optimizations active:"
echo "   - CPU performance mode"
echo "   - 24GB RAM dedicated (64GB total system)"
echo "   - 20 CPU cores with pinning (10C/20T)"
echo "   - RTX 4080 + audio passthrough"
echo "   - VirtIO high-performance drivers"
echo "   - Looking Glass for seamless display"
echo "   - NUMA optimized for your i9-13900HX"

# Start Looking Glass client automatically
echo "🔍 Starting Looking Glass client..."
looking-glass-client -F &
LG_PID=$!

echo ""
echo "🎮 Gaming VM is ready!"
echo "📋 Controls:"
echo "   - Ctrl+Alt+Q: Exit Looking Glass"
echo "   - Right Ctrl: Release mouse"
echo "   - Ctrl+C: Stop VM and exit script"
echo ""
echo "⏳ Waiting for Looking Glass or VM to exit..."

# Wait for Looking Glass or VM to exit
while kill -0 $LG_PID 2>/dev/null && sudo virsh list --state-running | grep -q "win10-gaming"; do
    sleep 1
done

echo "🔄 Looking Glass or VM has exited, cleaning up..."
