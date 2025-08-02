#!/bin/bash

# Gaming VM Setup Script
# Based on the high-performance gaming VM guide
# This script creates a new VM optimized for gaming with GPU passthrough

set -euo pipefail

# Configuration variables
VM_NAME="win10-gaming"
VM_MEMORY="40960"  # 40GB in MB
VM_VCPUS="20"
VM_CORES="10"
VM_THREADS="2"
VM_SOCKETS="1"

# CPU pinning - based on your guide's optimal configuration
# Cores 12-31 (avoiding cores 0-11 for host)
CPU_PIN_SET="12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31"

# Paths
DISK_PATH="/var/lib/libvirt/images/win10-gaming.qcow2"
ORIGINAL_DISK="/home/lou/Downloads/battlenet/windows-10-English-United-States/disk.qcow2"
VIRTIO_ISO="/tmp/virtio-win.iso"
INSTALL_ISO="/home/lou/Downloads/battlenet/windows-10-English-United-States/Win10_22H2_English_x64v1.iso"
UNATTENDED_ISO="/home/lou/Downloads/battlenet/windows-10-English-United-States/unattended.iso"
OVMF_VARS="/home/lou/Downloads/battlenet/windows-10-English-United-States/OVMF_VARS.fd"
OVMF_VARS_TARGET="/var/lib/libvirt/qemu/nvram/${VM_NAME}_VARS.fd"

# PCI device IDs for RTX 4080 (update these if needed)
GPU_PCI="0000:01:00.0"
GPU_AUDIO_PCI="0000:01:00.1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root/sudo
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if libvirt is running
    if ! systemctl is-active --quiet libvirtd; then
        error "libvirtd is not running. Please start it first."
        exit 1
    fi
    
    # Check if VFIO modules are loaded
    if ! lsmod | grep -q vfio_pci; then
        error "VFIO modules not loaded. Please ensure VFIO is properly configured."
        exit 1
    fi
    
    # Check if source files exist
    if [[ ! -f "$ORIGINAL_DISK" ]]; then
        error "Source disk not found: $ORIGINAL_DISK"
        exit 1
    fi
    
    if [[ ! -f "$INSTALL_ISO" ]]; then
        error "Windows ISO not found: $INSTALL_ISO"
        exit 1
    fi
    
    if [[ ! -f "$VIRTIO_ISO" ]]; then
        error "VirtIO ISO not found: $VIRTIO_ISO"
        exit 1
    fi
    
    log "Prerequisites check passed"
}

# Remove existing VM if it exists
cleanup_existing_vm() {
    log "Checking for existing VM..."
    
    if virsh list --all | grep -q "$VM_NAME"; then
        warn "Existing VM '$VM_NAME' found. Removing..."
        
        # Force shutdown if running
        if virsh list --state-running | grep -q "$VM_NAME"; then
            virsh destroy "$VM_NAME" || true
        fi
        
        # Undefine the VM
        virsh undefine "$VM_NAME" --nvram || true
        
        # Remove old disk if it exists
        if [[ -f "$DISK_PATH" ]]; then
            rm -f "$DISK_PATH"
        fi
        
        # Remove old NVRAM if it exists
        if [[ -f "$OVMF_VARS_TARGET" ]]; then
            rm -f "$OVMF_VARS_TARGET"
        fi
        
        log "Existing VM removed"
    fi
}

# Create the VM disk
create_disk() {
    log "Creating VM disk..."
    
    # Create a larger disk (120GB) for the gaming VM
    qemu-img create -f qcow2 "$DISK_PATH" 120G
    
    # Set proper ownership
    chown libvirt-qemu:libvirt-qemu "$DISK_PATH"
    chmod 660 "$DISK_PATH"
    
    log "VM disk created: $DISK_PATH"
}

# Copy OVMF variables
setup_ovmf() {
    log "Setting up OVMF variables..."
    
    cp "$OVMF_VARS" "$OVMF_VARS_TARGET"
    chown libvirt-qemu:libvirt-qemu "$OVMF_VARS_TARGET"
    chmod 660 "$OVMF_VARS_TARGET"
    
    log "OVMF variables configured"
}

# Create the VM XML definition
create_vm_xml() {
    log "Creating VM XML definition..."
    
    # Generate a random MAC address suffix
    MAC_ADDR=$(printf "%02x:%02x:%02x" $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
    
    cat > "/tmp/${VM_NAME}.xml" << EOF
<domain type='kvm'>
  <name>${VM_NAME}</name>
  <uuid>$(uuidgen)</uuid>
  <metadata>
    <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
      <libosinfo:os id="http://microsoft.com/win/10"/>
    </libosinfo:libosinfo>
  </metadata>
  <memory unit='KiB'>$(($VM_MEMORY * 1024))</memory>
  <currentMemory unit='KiB'>$(($VM_MEMORY * 1024))</currentMemory>
  <vcpu placement='static'>${VM_VCPUS}</vcpu>
  <cputune>
    <vcpupin vcpu='0' cpuset='12'/>
    <vcpupin vcpu='1' cpuset='13'/>
    <vcpupin vcpu='2' cpuset='14'/>
    <vcpupin vcpu='3' cpuset='15'/>
    <vcpupin vcpu='4' cpuset='16'/>
    <vcpupin vcpu='5' cpuset='17'/>
    <vcpupin vcpu='6' cpuset='18'/>
    <vcpupin vcpu='7' cpuset='19'/>
    <vcpupin vcpu='8' cpuset='20'/>
    <vcpupin vcpu='9' cpuset='21'/>
    <vcpupin vcpu='10' cpuset='22'/>
    <vcpupin vcpu='11' cpuset='23'/>
    <vcpupin vcpu='12' cpuset='24'/>
    <vcpupin vcpu='13' cpuset='25'/>
    <vcpupin vcpu='14' cpuset='26'/>
    <vcpupin vcpu='15' cpuset='27'/>
    <vcpupin vcpu='16' cpuset='28'/>
    <vcpupin vcpu='17' cpuset='29'/>
    <vcpupin vcpu='18' cpuset='30'/>
    <vcpupin vcpu='19' cpuset='31'/>
  </cputune>
  <os>
    <type arch='x86_64' machine='pc-q35-8.0'>hvm</type>
    <loader readonly='yes' type='pflash'>/usr/share/edk2-ovmf/x64/OVMF_CODE.fd</loader>
    <nvram>${OVMF_VARS_TARGET}</nvram>
    <bootmenu enable='no'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <hyperv mode='custom'>
      <relaxed state='on'/>
      <vapic state='on'/>
      <spinlocks state='on' retries='8191'/>
      <vendor_id state='on' value='KVM Hv'/>
    </hyperv>
    <vmport state='off'/>
  </features>
  <cpu mode='host-passthrough' check='none' migratable='on'>
    <topology sockets='${VM_SOCKETS}' dies='1' cores='${VM_CORES}' threads='${VM_THREADS}'/>
    <cache mode='passthrough'/>
  </cpu>
  <clock offset='localtime'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
    <timer name='hypervclock' present='yes'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none' io='native'/>
      <source file='${DISK_PATH}'/>
      <target dev='vda' bus='virtio'/>
      <boot order='1'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='${INSTALL_ISO}'/>
      <target dev='sdb' bus='sata'/>
      <readonly/>
      <boot order='2'/>
      <address type='drive' controller='0' bus='0' target='0' unit='1'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='${VIRTIO_ISO}'/>
      <target dev='sdc' bus='sata'/>
      <readonly/>
      <address type='drive' controller='0' bus='0' target='0' unit='2'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='${UNATTENDED_ISO}'/>
      <target dev='sdd' bus='sata'/>
      <readonly/>
      <address type='drive' controller='0' bus='0' target='0' unit='3'/>
    </disk>
    <controller type='usb' index='0' model='qemu-xhci' ports='15'>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>
    </controller>
    <controller type='pci' index='0' model='pcie-root'/>
    <controller type='pci' index='1' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='1' port='0x10'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0' multifunction='on'/>
    </controller>
    <controller type='pci' index='2' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='2' port='0x11'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>
    </controller>
    <controller type='pci' index='3' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='3' port='0x12'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x2'/>
    </controller>
    <controller type='pci' index='4' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='4' port='0x13'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x3'/>
    </controller>
    <controller type='pci' index='5' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='5' port='0x14'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x4'/>
    </controller>
    <controller type='pci' index='6' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='6' port='0x15'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x5'/>
    </controller>
    <controller type='pci' index='7' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='7' port='0x16'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x6'/>
    </controller>
    <controller type='pci' index='8' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='8' port='0x17'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x7'/>
    </controller>
    <controller type='pci' index='9' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='9' port='0x18'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0' multifunction='on'/>
    </controller>
    <controller type='pci' index='10' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='10' port='0x19'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x1'/>
    </controller>
    <controller type='pci' index='11' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='11' port='0x1a'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x2'/>
    </controller>
    <controller type='pci' index='12' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='12' port='0x1b'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x3'/>
    </controller>
    <controller type='pci' index='13' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='13' port='0x1c'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x4'/>
    </controller>
    <controller type='pci' index='14' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='14' port='0x1d'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x5'/>
    </controller>
    <controller type='sata' index='0'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>
    </controller>
    <controller type='virtio-serial' index='0'>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
    </controller>
    <interface type='network'>
      <mac address='52:54:00:${MAC_ADDR}'/>
      <source network='default'/>
      <model type='virtio'/>
      <driver name='vhost' queues='8'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>
    <serial type='pty'>
      <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
      </target>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <channel type='spicevmc'>
      <target type='virtio' name='com.redhat.spice.0'/>
      <address type='virtio-serial' controller='0' bus='0' port='1'/>
    </channel>
    <input type='tablet' bus='usb'>
      <address type='usb' bus='0' port='1'/>
    </input>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <graphics type='spice' port='5901' autoport='no' listen='127.0.0.1' passwd=''>
      <listen type='address' address='127.0.0.1'/>
      <image compression='off'/>
    </graphics>
    <sound model='ich9'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>
    </sound>
    <audio id='1' type='spice'/>
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
        <address domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
      </source>
      <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
    </hostdev>
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
        <address domain='0x0000' bus='0x01' slot='0x00' function='0x1'/>
      </source>
      <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>
    </hostdev>
    <redirdev bus='usb' type='spicevmc'>
      <address type='usb' bus='0' port='2'/>
    </redirdev>
    <redirdev bus='usb' type='spicevmc'>
      <address type='usb' bus='0' port='3'/>
    </redirdev>
    <memballoon model='virtio'>
      <address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>
    </memballoon>
    <rng model='virtio'>
      <backend model='random'>/dev/urandom</backend>
      <address type='pci' domain='0x0000' bus='0x08' slot='0x00' function='0x0'/>
    </rng>
    <shmem name='looking-glass'>
      <model type='ivshmem-plain'/>
      <size unit='M'>32</size>
      <address type='pci' domain='0x0000' bus='0x10' slot='0x01' function='0x0'/>
    </shmem>
  </devices>
</domain>
EOF

    log "VM XML definition created"
}

# Define the VM
define_vm() {
    log "Defining VM in libvirt..."
    
    virsh define "/tmp/${VM_NAME}.xml"
    rm "/tmp/${VM_NAME}.xml"
    
    log "VM defined successfully"
}

# Create shared memory device for Looking Glass
setup_looking_glass() {
    log "Setting up Looking Glass shared memory..."
    
    # Create the shared memory file if it doesn't exist
    if [[ ! -f /dev/shm/looking-glass ]]; then
        touch /dev/shm/looking-glass
        chown libvirt-qemu:libvirt-qemu /dev/shm/looking-glass
        chmod 660 /dev/shm/looking-glass
    fi
    
    log "Looking Glass shared memory configured"
}

# Create start script
create_start_script() {
    log "Creating start script..."
    
    cat > "/home/lou/Scripts/start-gaming-vm-new.sh" << 'EOF'
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
EOF

    chmod +x "/home/lou/Scripts/start-gaming-vm-new.sh"
    chown lou:lou "/home/lou/Scripts/start-gaming-vm-new.sh"
    
    log "Start script created: /home/lou/Scripts/start-gaming-vm-new.sh"
}

# Create stop script
create_stop_script() {
    log "Creating stop script..."
    
    cat > "/home/lou/Scripts/stop-gaming-vm-new.sh" << 'EOF'
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
EOF

    chmod +x "/home/lou/Scripts/stop-gaming-vm-new.sh"
    chown lou:lou "/home/lou/Scripts/stop-gaming-vm-new.sh"
    
    log "Stop script created: /home/lou/Scripts/stop-gaming-vm-new.sh"
}

# Main execution
main() {
    log "Starting Gaming VM setup..."
    
    check_permissions
    check_prerequisites
    cleanup_existing_vm
    create_disk
    setup_ovmf
    create_vm_xml
    define_vm
    setup_looking_glass
    create_start_script
    create_stop_script
    
    log "Gaming VM setup complete!"
    echo ""
    log "Next steps:"
    log "1. Start the VM: sudo /home/lou/Scripts/start-gaming-vm-new.sh"
    log "2. Install Windows using the ISOs mounted"
    log "3. Install VirtIO drivers from the mounted ISO"
    log "4. Install Looking Glass host application in Windows"
    log "5. Install Battle.net and Diablo IV"
    echo ""
    log "The VM is configured with:"
    log "- 40GB RAM"
    log "- 20 CPU cores (12-31) pinned for optimal performance"
    log "- RTX 4080 GPU passthrough"
    log "- Looking Glass for low-latency display"
    log "- VirtIO storage and network for best performance"
    echo ""
    warn "Make sure to install the Looking Glass host app in Windows for seamless display!"
}

# Run main function
main "$@"
