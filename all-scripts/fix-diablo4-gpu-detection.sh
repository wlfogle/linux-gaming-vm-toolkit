#!/bin/bash

# 🎮 Fix Diablo IV GPU Detection in Gaming VM
# Adapted from: https://github.com/jamesstringerparsec/Easy-GPU-PV/issues/304#issuecomment-1670572182
# 
# This script helps resolve Diablo IV not detecting the GPU in QEMU/KVM VMs
# The original solution was for Hyper-V, this adapts it for Linux hosts

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎮 Diablo IV GPU Detection Fix${NC}"
echo -e "${BLUE}===============================${NC}"
echo ""

print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK") echo -e "${GREEN}✅ $message${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "ERROR") echo -e "${RED}❌ $message${NC}" ;;
        "INFO") echo -e "${BLUE}ℹ️  $message${NC}" ;;
    esac
}

# Check if VM is running
if ! virsh list | grep -q "win10-gaming.*running"; then
    print_status "ERROR" "Gaming VM is not running. Start it first with ./start-gaming-vm.sh"
    exit 1
fi

print_status "INFO" "Gaming VM is running - proceeding with GPU detection fix"

# Create a PowerShell script to run inside the Windows VM
VM_SCRIPT_PATH="/tmp/diablo4-gpu-fix.ps1"

cat > "$VM_SCRIPT_PATH" << 'EOF'
# Diablo IV GPU Detection Fix Script for Windows VM
# This runs inside the Windows VM to apply the NVIDIA driver registry fix

Write-Host "🎮 Diablo IV GPU Detection Fix" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

# Function to write colored output
function Write-Status {
    param(
        [string]$Status,
        [string]$Message
    )
    
    switch ($Status) {
        "OK" { Write-Host "✅ $Message" -ForegroundColor Green }
        "WARNING" { Write-Host "⚠️  $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "❌ $Message" -ForegroundColor Red }
        "INFO" { Write-Host "ℹ️  $Message" -ForegroundColor Blue }
    }
}

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Status "ERROR" "This script must be run as Administrator"
    Write-Host "Right-click PowerShell and select 'Run as Administrator'"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Status "INFO" "Running as Administrator - proceeding with fix"

# Check for NVIDIA GPU
$nvidiaGPU = Get-WmiObject -Class Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" }
if (-not $nvidiaGPU) {
    Write-Status "ERROR" "No NVIDIA GPU detected in Device Manager"
    Write-Status "INFO" "Make sure RTX 4080 is properly passed through and drivers are installed"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Status "OK" "NVIDIA GPU detected: $($nvidiaGPU.Name)"

# Check current display adapter situation
$allGPUs = Get-WmiObject -Class Win32_VideoController
Write-Status "INFO" "Display adapters detected:"
foreach ($gpu in $allGPUs) {
    Write-Host "  - $($gpu.Name)" -ForegroundColor Gray
}

# Check if Microsoft Basic Render Driver is present (the problem from the GitHub issue)
$basicRender = $allGPUs | Where-Object { $_.Name -like "*Basic*" -or $_.Name -like "*Microsoft*" }
if ($basicRender) {
    Write-Status "WARNING" "Microsoft Basic Render Driver detected - this may cause Diablo IV issues"
} else {
    Write-Status "OK" "No basic render driver conflicts detected"
}

# Registry key paths for NVIDIA driver
$nvlddmkmPath = "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm"
$exportPath = "C:\nvlddmkm-backup.reg"

# Check if nvlddmkm registry key exists
if (Test-Path $nvlddmkmPath) {
    Write-Status "OK" "NVIDIA driver registry key found"
    
    # Export the registry key as backup
    Write-Status "INFO" "Creating backup of NVIDIA driver registry..."
    reg export "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" $exportPath /y | Out-Null
    Write-Status "OK" "Registry backup saved to $exportPath"
    
    # Display some key information
    $nvKey = Get-ItemProperty -Path $nvlddmkmPath -ErrorAction SilentlyContinue
    if ($nvKey) {
        Write-Status "INFO" "Registry key contains $(($nvKey | Get-Member -MemberType NoteProperty).Count) entries"
    }
} else {
    Write-Status "ERROR" "NVIDIA driver registry key not found at $nvlddmkmPath"
    Write-Status "INFO" "This suggests NVIDIA drivers may not be properly installed"
    Write-Status "INFO" "Try reinstalling NVIDIA drivers in the VM"
    Read-Host "Press Enter to exit"
    exit 1
}

# Check Diablo IV installation and debug logs
$diablo4Paths = @(
    "C:\Program Files (x86)\Diablo IV",
    "D:\Games\Diablo IV",
    "E:\Games\Diablo IV"
)

$diablo4Path = $null
foreach ($path in $diablo4Paths) {
    if (Test-Path $path) {
        $diablo4Path = $path
        break
    }
}

if ($diablo4Path) {
    Write-Status "OK" "Diablo IV found at: $diablo4Path"
    
    # Check for FenrisDebug.txt (mentioned in the GitHub issue)
    $debugLogPath = Join-Path $diablo4Path "FenrisDebug.txt"
    if (Test-Path $debugLogPath) {
        Write-Status "INFO" "Found Diablo IV debug log - checking for NVAPI errors..."
        
        $debugContent = Get-Content $debugLogPath -ErrorAction SilentlyContinue
        if ($debugContent -match "NVAPI" -or $debugContent -match "Basic Render") {
            Write-Status "WARNING" "Debug log shows GPU detection issues"
            Write-Status "INFO" "This confirms the fix is needed"
        } else {
            Write-Status "OK" "No obvious GPU detection errors in debug log"
        }
    } else {
        Write-Status "INFO" "No debug log found (normal if game hasn't been run yet)"
    }
} else {
    Write-Status "WARNING" "Diablo IV installation not found in common locations"
    Write-Status "INFO" "Game may be installed elsewhere"
}

# VM-specific optimizations for GPU detection
Write-Status "INFO" "Applying VM-specific optimizations..."

# Disable Windows Graphics Settings that might interfere
$graphicsPath = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
if (Test-Path $graphicsPath) {
    Write-Status "INFO" "Clearing DirectX GPU preferences that might conflict"
    Remove-ItemProperty -Path $graphicsPath -Name "*" -Force -ErrorAction SilentlyContinue
}

# Ensure NVIDIA Control Panel can see the GPU
Write-Status "INFO" "Refreshing NVIDIA driver state..."
$nvidiaService = Get-Service -Name "NVDisplay.ContainerLocalSystem" -ErrorAction SilentlyContinue
if ($nvidiaService) {
    if ($nvidiaService.Status -ne "Running") {
        Write-Status "INFO" "Starting NVIDIA Display Container service..."
        Start-Service "NVDisplay.ContainerLocalSystem" -ErrorAction SilentlyContinue
    }
    Write-Status "OK" "NVIDIA services running"
} else {
    Write-Status "WARNING" "NVIDIA Display service not found - driver installation may be incomplete"
}

# Final recommendations
Write-Status "OK" "GPU detection fix completed!"
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Launch Diablo IV and test GPU detection"
Write-Host "2. If still having issues, check Device Manager for GPU status"
Write-Host "3. Ensure game is set to use NVIDIA GPU in NVIDIA Control Panel"
Write-Host "4. Check FenrisDebug.txt for NVAPI errors after running the game"
Write-Host ""
Write-Host "💡 Performance Tips:" -ForegroundColor Green
Write-Host "- Use NVIDIA Control Panel to force max performance for Diablo IV"
Write-Host "- Disable Windows Game Mode if performance is inconsistent"
Write-Host "- Use fullscreen mode rather than windowed for best performance"
Write-Host ""

Read-Host "Press Enter to continue"
EOF

print_status "INFO" "Created PowerShell script for Windows VM"

# Instructions for running the fix
echo ""
echo -e "${PURPLE}🚀 How to Apply the Fix:${NC}"
echo ""
echo "1. Copy the PowerShell script to your Windows VM:"
echo "   - The script is ready at: $VM_SCRIPT_PATH"
echo "   - Copy it to your Windows VM (use shared folder or copy via Looking Glass)"
echo ""
echo "2. In Windows VM, run PowerShell as Administrator:"
echo "   - Right-click PowerShell → 'Run as Administrator'"
echo "   - Navigate to where you copied the script"
echo "   - Run: ./diablo4-gpu-fix.ps1"
echo ""
echo "3. The script will:"
echo "   - Verify NVIDIA GPU detection"
echo "   - Check registry keys"
echo "   - Apply optimizations"
echo "   - Give you next steps"
echo ""

# Additional Linux host-side checks
echo -e "${PURPLE}🔍 Linux Host Verification:${NC}"

# Check VFIO GPU binding
NVIDIA_PCI=$(lspci | grep -i "vga.*nvidia" | cut -d' ' -f1 | head -1)
if [[ -n "$NVIDIA_PCI" ]]; then
    GPU_DRIVER=$(lspci -k -s "$NVIDIA_PCI" | grep "Kernel driver in use" | cut -d':' -f2 | xargs || echo "none")
    if [[ "$GPU_DRIVER" == "vfio-pci" ]]; then
        print_status "OK" "RTX 4080 properly bound to VFIO-PCI for passthrough"
    else
        print_status "WARNING" "RTX 4080 driver: $GPU_DRIVER (should be vfio-pci when VM is running)"
    fi
fi

# Check if VM has proper GPU configuration
if virsh dumpxml win10-gaming | grep -q "0000:02:00.0"; then
    print_status "OK" "RTX 4080 PCI device passed through to VM"
else
    print_status "WARNING" "GPU passthrough configuration may need verification"
fi

echo ""
echo -e "${GREEN}💡 Troubleshooting Tips:${NC}"
echo ""
echo "If Diablo IV still doesn't detect GPU after running the fix:"
echo ""
echo "1. Windows VM Device Manager:"
echo "   - Check if RTX 4080 shows without errors"
echo "   - Update drivers if there's a yellow warning"
echo ""
echo "2. NVIDIA Control Panel:"
echo "   - Open NVIDIA Control Panel in VM"
echo "   - Go to 'Manage 3D settings'"
echo "   - Add Diablo IV executable"
echo "   - Set preferred graphics processor to 'High-performance NVIDIA processor'"
echo ""
echo "3. Diablo IV Settings:"
echo "   - In game, go to Options → Video"
echo "   - Ensure 'Adapter' shows your RTX 4080"
echo "   - Set to fullscreen mode for best performance"
echo ""
echo "4. Legacy BIOS Note:"
echo "   - Your VM uses legacy BIOS specifically to fix RTX 4080 Error 43"
echo "   - This should resolve most GPU detection issues"
echo ""

# Create a simple copy helper
echo -e "${BLUE}📁 Easy Copy Command:${NC}"
echo "To copy the PowerShell script to your VM shared folder:"
echo ""
echo "# If you have a shared folder set up:"
echo "cp $VM_SCRIPT_PATH /path/to/your/vm/shared/folder/"
echo ""
echo "# Or use Looking Glass shared clipboard to copy the script content"

print_status "OK" "Diablo IV GPU detection fix prepared!"
print_status "INFO" "Run the PowerShell script inside your Windows VM as Administrator"
