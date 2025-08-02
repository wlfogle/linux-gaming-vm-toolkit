#!/bin/bash

VM_NAME="win10-gaming"
LOOKING_GLASS_CLIENT="/usr/bin/looking-glass-client"
SPICE_PORT="5901"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if VM is already running
if virsh list --state-running | grep -q "$VM_NAME"; then
    warn "VM $VM_NAME is already running"
    exit 0
fi

# Stop conflicting VMs
log "Stopping any conflicting VMs..."
for vm in proxmox-selfhost; do
    if virsh list --state-running | grep -q "$vm"; then
        log "Stopping $vm..."
        virsh shutdown "$vm"
        sleep 3
    fi
done

# Set CPU performance
log "Setting CPU performance mode..."
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null

# Disable swap
log "Disabling swap..."
sudo swapoff -a

# Start the VM
log "Starting VM $VM_NAME..."
virsh start "$VM_NAME"

# Wait for VM to boot
log "Waiting for VM to start..."
sleep 10

# Check if Looking Glass client exists and start it
if [[ -x "$LOOKING_GLASS_CLIENT" ]]; then
    log "Starting Looking Glass client..."
    # Kill any existing Looking Glass instances
    pkill -f looking-glass-client || true
    sleep 2
    
    # Start Looking Glass client in background
    nohup "$LOOKING_GLASS_CLIENT" -p "$SPICE_PORT" > /dev/null 2>&1 &
    log "Looking Glass client started"
else
    warn "Looking Glass client not found. You can connect with virt-viewer instead:"
    warn "virt-viewer -c qemu:///system $VM_NAME"
fi

log "Gaming VM startup complete!"
log "If Looking Glass doesn't work, try: virt-viewer -c qemu:///system $VM_NAME"
