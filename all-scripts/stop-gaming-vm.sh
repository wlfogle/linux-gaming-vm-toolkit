#!/bin/bash

echo "🛑 Stopping Gaming VM and restoring system..."

# Stop VM
echo "⏹️ Shutting down VM..."
sudo virsh shutdown win10-gaming

# Wait for VM to stop
echo "⏳ Waiting for VM to shutdown..."
while sudo virsh list --state-running | grep -q win10-gaming; do
    sleep 2
done

# Unbind GPU from VFIO and rebind to nvidia
echo "🔄 Restoring GPU to NVIDIA driver..."
echo 0000:02:00.0 | sudo tee /sys/bus/pci/drivers/vfio-pci/unbind > /dev/null 2>&1
echo 0000:02:00.1 | sudo tee /sys/bus/pci/drivers/vfio-pci/unbind > /dev/null 2>&1

# Remove VFIO IDs
echo 10de 27e0 | sudo tee /sys/bus/pci/drivers/vfio-pci/remove_id > /dev/null 2>&1
echo 10de 22bc | sudo tee /sys/bus/pci/drivers/vfio-pci/remove_id > /dev/null 2>&1

# Rebind to nvidia
sudo modprobe nvidia
echo 0000:02:00.0 | sudo tee /sys/bus/pci/drivers/nvidia/bind > /dev/null 2>&1
echo 0000:02:00.1 | sudo tee /sys/bus/pci/drivers/snd_hda_intel/bind > /dev/null 2>&1

# Restore CPU governor
echo "⚡ Restoring CPU governor..."
echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null

# Re-enable swap
echo "🔄 Re-enabling swap..."
sudo swapon -a

# Restore I/O scheduler
echo "💾 Restoring I/O scheduler..."
echo bfq | sudo tee /sys/block/nvme*/queue/scheduler > /dev/null

echo "✅ System restored to normal operation!"
echo "🖥️ Your NVIDIA GPU is now available for Linux again"
