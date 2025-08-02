#!/bin/bash

VM_NAME="win10-gaming"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Stop Looking Glass client
log "Stopping Looking Glass client..."
pkill -f looking-glass-client || true

# Check if VM is running
if ! virsh list --state-running | grep -q "$VM_NAME"; then
    log "VM $VM_NAME is not running"
    exit 0
fi

# Graceful shutdown
log "Shutting down VM $VM_NAME..."
virsh shutdown "$VM_NAME"

# Wait for shutdown
log "Waiting for VM to shutdown..."
timeout=60
while [[ $timeout -gt 0 ]] && virsh list --state-running | grep -q "$VM_NAME"; do
    sleep 1
    ((timeout--))
done

# Force stop if still running
if virsh list --state-running | grep -q "$VM_NAME"; then
    log "Force stopping VM..."
    virsh destroy "$VM_NAME"
fi

# Reset CPU governor
log "Resetting CPU governor to powersave..."
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null

# Re-enable swap
log "Re-enabling swap..."
sudo swapon -a

log "Gaming VM stopped successfully!"
