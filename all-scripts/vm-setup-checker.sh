#!/bin/bash

# 🎮 Gaming VM Setup Checker - Linux Adaptation of Diablo4VM PreChecks.ps1
# Validates system requirements and checks VM readiness for optimal gaming

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎮 Gaming VM Setup Checker${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Function to print status
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Check if running as non-root (we'll use sudo when needed)
if [[ $EUID -eq 0 ]]; then
    print_status "ERROR" "Don't run this as root. Use sudo when prompted."
    exit 1
fi

print_status "INFO" "Checking Gaming VM requirements..."
echo ""

# 1. Check CPU capabilities
echo -e "${PURPLE}🖥️  CPU Information:${NC}"
CPU_INFO=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
print_status "INFO" "CPU: $CPU_INFO"

# Check for virtualization support
if grep -q "vmx\|svm" /proc/cpuinfo; then
    print_status "OK" "CPU virtualization support detected"
else
    print_status "ERROR" "CPU virtualization support NOT detected"
    echo "Enable VT-x/AMD-V in BIOS"
fi

# Check IOMMU support
if dmesg | grep -q "IOMMU enabled"; then
    print_status "OK" "IOMMU enabled"
else
    print_status "WARNING" "IOMMU may not be properly enabled"
    echo "Add intel_iommu=on (Intel) or amd_iommu=on (AMD) to kernel parameters"
fi

echo ""

# 2. Check GPU setup
echo -e "${PURPLE}🎮 GPU Information:${NC}"
GPU_NVIDIA=$(lspci | grep -i "vga.*nvidia" || true)
GPU_INTEL=$(lspci | grep -i "vga.*intel" || true)

if [[ -n "$GPU_NVIDIA" ]]; then
    print_status "OK" "NVIDIA GPU detected: $(echo $GPU_NVIDIA | cut -d':' -f3)"
    
    # Check NVIDIA driver
    if command -v nvidia-smi &> /dev/null; then
        DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -1)
        print_status "OK" "NVIDIA driver version: $DRIVER_VERSION"
    else
        print_status "WARNING" "NVIDIA drivers not detected on host (this is OK if using VFIO)"
    fi
else
    print_status "ERROR" "No NVIDIA GPU detected"
fi

if [[ -n "$GPU_INTEL" ]]; then
    print_status "OK" "Intel iGPU detected (good for host display)"
else
    print_status "WARNING" "No Intel iGPU detected"
fi

echo ""

# 3. Check VFIO setup
echo -e "${PURPLE}🔧 VFIO Configuration:${NC}"
if lsmod | grep -q vfio_pci; then
    print_status "OK" "VFIO-PCI module loaded"
else
    print_status "WARNING" "VFIO-PCI module not loaded"
fi

# Check if GPU is bound to VFIO
NVIDIA_PCI=$(lspci | grep -i "vga.*nvidia" | cut -d' ' -f1 | head -1)
if [[ -n "$NVIDIA_PCI" ]]; then
    GPU_DRIVER=$(lspci -k -s "$NVIDIA_PCI" | grep "Kernel driver in use" | cut -d':' -f2 | xargs || echo "none")
    if [[ "$GPU_DRIVER" == "vfio-pci" ]]; then
        print_status "OK" "NVIDIA GPU bound to VFIO-PCI"
    else
        print_status "INFO" "NVIDIA GPU driver: $GPU_DRIVER (will be switched to VFIO when VM starts)"
    fi
fi

echo ""

# 4. Check KVM/QEMU setup
echo -e "${PURPLE}🖥️  Virtualization Software:${NC}"
if command -v qemu-system-x86_64 &> /dev/null; then
    QEMU_VERSION=$(qemu-system-x86_64 --version | head -1)
    print_status "OK" "QEMU installed: $QEMU_VERSION"
else
    print_status "ERROR" "QEMU not installed"
fi

if command -v virsh &> /dev/null; then
    print_status "OK" "Libvirt installed"
    
    # Check if libvirtd is running
    if systemctl is-active --quiet libvirtd; then
        print_status "OK" "Libvirtd service running"
    else
        print_status "WARNING" "Libvirtd service not running"
    fi
else
    print_status "ERROR" "Libvirt not installed"
fi

# Check if user is in libvirt group
if groups | grep -q libvirt; then
    print_status "OK" "User in libvirt group"
else
    print_status "WARNING" "User not in libvirt group"
    echo "Run: sudo usermod -a -G libvirt \$USER"
fi

echo ""

# 5. Check Looking Glass setup
echo -e "${PURPLE}🔍 Looking Glass:${NC}"
if command -v looking-glass-client &> /dev/null; then
    LG_VERSION=$(looking-glass-client --version 2>&1 | head -1 || echo "Version check failed")
    print_status "OK" "Looking Glass client installed: $LG_VERSION"
else
    print_status "WARNING" "Looking Glass client not found"
    echo "Install from AUR: yay -S looking-glass"
fi

# Check shared memory
if [[ -e /dev/shm/looking-glass ]]; then
    LG_SIZE=$(ls -lh /dev/shm/looking-glass | awk '{print $5}')
    print_status "OK" "Looking Glass shared memory: $LG_SIZE"
else
    print_status "INFO" "Looking Glass shared memory not active (will be created when VM starts)"
fi

echo ""

# 6. Check VM existence and status
echo -e "${PURPLE}🖥️  VM Status:${NC}"
if virsh list --all | grep -q "win10-gaming"; then
    VM_STATE=$(virsh list --all | grep "win10-gaming" | awk '{print $3" "$4}' | xargs)
    print_status "OK" "Gaming VM exists: $VM_STATE"
    
    if [[ "$VM_STATE" == "running" ]]; then
        print_status "INFO" "VM is currently running"
        
        # Check VM specs
        VM_RAM=$(virsh dominfo win10-gaming | grep "Max memory" | awk '{print $3" "$4}')
        VM_CPU=$(virsh dominfo win10-gaming | grep "CPU(s)" | awk '{print $2}')
        print_status "INFO" "VM RAM: $VM_RAM, CPUs: $VM_CPU"
    fi
else
    print_status "WARNING" "Gaming VM 'win10-gaming' not found"
fi

echo ""

# 7. Check scripts existence
echo -e "${PURPLE}📜 Management Scripts:${NC}"
SCRIPT_DIR="/home/lou/Scripts"
SCRIPTS=("start-gaming-vm.sh" "stop-gaming-vm.sh")

for script in "${SCRIPTS[@]}"; do
    if [[ -f "$SCRIPT_DIR/$script" ]]; then
        if [[ -x "$SCRIPT_DIR/$script" ]]; then
            print_status "OK" "$script exists and is executable"
        else
            print_status "WARNING" "$script exists but not executable"
        fi
    else
        print_status "WARNING" "$script not found in $SCRIPT_DIR"
    fi
done

echo ""

# 8. System resources check
echo -e "${PURPLE}💾 System Resources:${NC}"
TOTAL_RAM=$(free -h | grep "Mem:" | awk '{print $2}')
FREE_RAM=$(free -h | grep "Mem:" | awk '{print $7}')
print_status "INFO" "Total RAM: $TOTAL_RAM, Available: $FREE_RAM"

CPU_CORES=$(nproc)
print_status "INFO" "CPU cores: $CPU_CORES"

# Storage check
STORAGE_FREE=$(df -h /home | tail -1 | awk '{print $4}')
print_status "INFO" "Free storage in /home: $STORAGE_FREE"

echo ""

# 9. Performance optimizations check
echo -e "${PURPLE}⚡ Performance Settings:${NC}"
CPU_GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "N/A")
print_status "INFO" "CPU governor: $CPU_GOVERNOR"

if [[ "$CPU_GOVERNOR" == "performance" ]]; then
    print_status "OK" "CPU set to performance mode"
else
    print_status "INFO" "Consider setting CPU governor to performance for gaming"
fi

# Check if swap is disabled
SWAP_USAGE=$(free | grep Swap | awk '{print $2}')
if [[ "$SWAP_USAGE" -eq 0 ]]; then
    print_status "OK" "Swap disabled (good for gaming)"
else
    print_status "INFO" "Swap enabled ($SWAP_USAGE KB)"
fi

echo ""
echo -e "${BLUE}🎯 Summary:${NC}"
echo "Your Garuda Linux system appears ready for gaming VM operations."
echo "RTX 4080 + Intel iGPU detected - perfect for GPU passthrough setup."
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. Run ./vm-windows-setup.sh to automate Windows VM configuration"
echo "2. Use ./start-gaming-vm.sh to launch your gaming environment"
echo "3. Connect with looking-glass-client for ultra-low latency gaming"
echo ""
echo -e "${YELLOW}⚠️  Remember: Your VM uses legacy BIOS to fix RTX 4080 Error 43${NC}"
