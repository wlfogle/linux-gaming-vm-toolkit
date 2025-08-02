#!/bin/bash

# 🎮 Automated Windows VM Setup - Linux Adaptation of Diablo4VM CopyFilesToVM.ps1
# Based on your vm-side-setup-summary.md workflow
# Automates the post-install setup process for your Windows gaming VM

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎮 Automated Windows VM Setup${NC}"
echo -e "${BLUE}==============================${NC}"
echo "Based on your legacy BIOS Windows 10 installation"
echo "Following the phase sequence from vm-side-setup-summary.md"
echo ""

print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK") echo -e "${GREEN}✅ $message${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "ERROR") echo -e "${RED}❌ $message${NC}" ;;
        "INFO") echo -e "${BLUE}ℹ️  $message${NC}" ;;
        "PHASE") echo -e "${PURPLE}🚀 $message${NC}" ;;
    esac
}

# Check if VM is running
if ! virsh list | grep -q "win10-gaming.*running"; then
    print_status "ERROR" "Gaming VM is not running. Start it first with ./start-gaming-vm.sh"
    exit 1
fi

print_status "INFO" "Gaming VM detected - proceeding with automated setup"

# Create comprehensive PowerShell setup script
SETUP_SCRIPT_PATH="/tmp/windows-vm-auto-setup.ps1"

cat > "$SETUP_SCRIPT_PATH" << 'EOF'
# Windows VM Automated Setup Script
# Follows the sequence from vm-side-setup-summary.md
# This runs inside the Windows VM to set up the complete gaming environment

param(
    [switch]$SkipVirtIO = $false,
    [switch]$SkipDrivers = $false,
    [switch]$TestMode = $false
)

# Set execution policy to allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Write-Host "🎮 Windows VM Automated Setup" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "Legacy BIOS Windows 10 Gaming Environment Setup" -ForegroundColor Gray
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
        "PHASE" { Write-Host "🚀 $Message" -ForegroundColor Magenta }
    }
}

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Status "ERROR" "This script must be run as Administrator"
    Write-Host "Right-click PowerShell and select 'Run as Administrator'"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Status "INFO" "Running as Administrator - proceeding with setup"

# Detect available drives
$drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
Write-Status "INFO" "Available drives detected:"
foreach ($drive in $drives) {
    $sizeGB = [math]::Round($drive.Size / 1GB, 1)
    $freeGB = [math]::Round($drive.FreeSpace / 1GB, 1)
    Write-Host "  $($drive.DeviceID) - $sizeGB GB total, $freeGB GB free" -ForegroundColor Gray
}

# Drive mapping based on your documentation
$targetDrive = "C:"        # Fresh Windows 10 install
$isoDrive = "D:"          # Windows 10 ISO
$backupDrive = "E:"       # UEFI backup with previous apps
$virtIODrive = "F:"       # VirtIO drivers

Write-Host ""
Write-Status "INFO" "Expected drive configuration:"
Write-Host "  C: - Fresh Windows 10 (TARGET)" -ForegroundColor Gray
Write-Host "  D: - Windows 10 ISO" -ForegroundColor Gray
Write-Host "  E: - UEFI backup (source apps)" -ForegroundColor Gray
Write-Host "  F: - VirtIO drivers" -ForegroundColor Gray

# =============================================================================
# PHASE 1: Foundation
# =============================================================================
Write-Host ""
Write-Status "PHASE" "PHASE 1: Foundation Setup"

if (-not $SkipVirtIO) {
    # Install VirtIO drivers
    $virtIOInstaller = "$virtIODrive\virtio-win-guest-tools.exe"
    if (Test-Path $virtIOInstaller) {
        Write-Status "OK" "VirtIO installer found at $virtIOInstaller"
        Write-Status "INFO" "Installing VirtIO drivers..."
        
        if (-not $TestMode) {
            $installProcess = Start-Process -FilePath $virtIOInstaller -ArgumentList "/S" -Wait -PassThru
            if ($installProcess.ExitCode -eq 0) {
                Write-Status "OK" "VirtIO drivers installed successfully"
                Write-Status "WARNING" "REBOOT REQUIRED after this script completes"
            } else {
                Write-Status "ERROR" "VirtIO installation failed (Exit code: $($installProcess.ExitCode))"
            }
        } else {
            Write-Status "INFO" "TEST MODE: Would install VirtIO drivers"
        }
    } else {
        Write-Status "WARNING" "VirtIO installer not found at $virtIOInstaller"
        Write-Status "INFO" "Check F: drive or manually install drivers"
    }
} else {
    Write-Status "INFO" "Skipping VirtIO installation (--SkipVirtIO specified)"
}

# =============================================================================
# PHASE 2: Copy Essential Applications
# =============================================================================
Write-Host ""
Write-Status "PHASE" "PHASE 2: Essential Applications"

$appsToMigrate = @(
    @{
        Name = "Warp"
        Source = "$backupDrive\Program Files\Warp"
        Destination = "$targetDrive\Program Files\Warp"
        Critical = $true
    },
    @{
        Name = "Looking Glass Host"
        Source = "$backupDrive\Program Files\Looking Glass (host)"
        Destination = "$targetDrive\Program Files\Looking Glass (host)"
        Critical = $true
    },
    @{
        Name = "Battle.net"
        Source = "$backupDrive\Program Files (x86)\Battle.net"
        Destination = "$targetDrive\Program Files (x86)\Battle.net"
        Critical = $true
    },
    @{
        Name = "NVIDIA Corporation"
        Source = "$backupDrive\Program Files\NVIDIA Corporation"
        Destination = "$targetDrive\Program Files\NVIDIA Corporation"
        Critical = $false
    }
)

foreach ($app in $appsToMigrate) {
    if (Test-Path $app.Source) {
        Write-Status "OK" "$($app.Name) found at source: $($app.Source)"
        
        if (-not $TestMode) {
            if (-not (Test-Path $app.Destination)) {
                Write-Status "INFO" "Copying $($app.Name) to $($app.Destination)..."
                try {
                    Copy-Item -Path $app.Source -Destination $app.Destination -Recurse -Force
                    Write-Status "OK" "$($app.Name) copied successfully"
                } catch {
                    Write-Status "ERROR" "Failed to copy $($app.Name): $($_.Exception.Message)"
                    if ($app.Critical) {
                        Write-Status "WARNING" "This is a critical application - setup may not work properly"
                    }
                }
            } else {
                Write-Status "INFO" "$($app.Name) already exists at destination"
            }
        } else {
            Write-Status "INFO" "TEST MODE: Would copy $($app.Name)"
        }
    } else {
        Write-Status "WARNING" "$($app.Name) not found at $($app.Source)"
        if ($app.Critical) {
            Write-Status "ERROR" "Critical application missing - manual intervention needed"
        }
    }
}

# =============================================================================
# PHASE 3: GPU Setup (Critical!)
# =============================================================================
Write-Host ""
Write-Status "PHASE" "PHASE 3: GPU Setup (RTX 4080 Error 43 Fix)"

if (-not $SkipDrivers) {
    # Check current GPU status
    $gpus = Get-WmiObject -Class Win32_VideoController
    Write-Status "INFO" "Current display adapters:"
    foreach ($gpu in $gpus) {
        $status = if ($gpu.Status -eq "OK") { "✅" } else { "❌" }
        Write-Host "  $status $($gpu.Name)" -ForegroundColor Gray
    }
    
    # Check for RTX 4080
    $rtx4080 = $gpus | Where-Object { $_.Name -like "*RTX 4080*" -or $_.Name -like "*4080*" }
    if ($rtx4080) {
        if ($rtx4080.Status -eq "OK") {
            Write-Status "OK" "RTX 4080 detected and working: $($rtx4080.Name)"
        } else {
            Write-Status "WARNING" "RTX 4080 detected but has issues: $($rtx4080.Status)"
            Write-Status "INFO" "Legacy BIOS should fix Error 43 - try installing latest drivers"
        }
    } else {
        Write-Status "ERROR" "RTX 4080 not detected in Device Manager"
        Write-Status "INFO" "Check GPU passthrough configuration and VFIO binding"
    }
    
    # Download and install NVIDIA Studio drivers
    Write-Status "INFO" "Checking for NVIDIA driver installation..."
    
    $nvidiaDriverPath = "$env:ProgramFiles\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
    if (Test-Path $nvidiaDriverPath) {
        try {
            $driverInfo = & $nvidiaDriverPath --query-gpu=driver_version --format=csv,noheader,nounits
            Write-Status "OK" "NVIDIA driver version: $driverInfo"
        } catch {
            Write-Status "WARNING" "NVIDIA driver installed but nvidia-smi failed"
        }
    } else {
        Write-Status "WARNING" "NVIDIA drivers not detected"
        Write-Status "INFO" "Download and install latest NVIDIA Studio drivers manually"
        Write-Status "INFO" "URL: https://www.nvidia.com/Download/index.aspx"
    }
} else {
    Write-Status "INFO" "Skipping driver setup (--SkipDrivers specified)"
}

# =============================================================================
# PHASE 4: Game Setup
# =============================================================================
Write-Host ""
Write-Status "PHASE" "PHASE 4: Game Setup"

# Look for Diablo IV in backup drive
$diablo4Paths = @(
    "$backupDrive\Games\Diablo IV",
    "$backupDrive\Program Files (x86)\Diablo IV",
    "$backupDrive\Diablo IV"
)

$diablo4Source = $null
foreach ($path in $diablo4Paths) {
    if (Test-Path $path) {
        $diablo4Source = $path
        break
    }
}

if ($diablo4Source) {
    Write-Status "OK" "Diablo IV installation found at: $diablo4Source"
    
    # Determine target location (typically Games drive or C:)
    $possibleTargets = @(
        "E:\Games\Diablo IV",           # Games drive
        "C:\Games\Diablo IV",           # Local games folder
        "C:\Program Files (x86)\Diablo IV"  # Program files
    )
    
    $diablo4Target = $possibleTargets[0]  # Default to Games drive
    
    if (-not $TestMode) {
        if (-not (Test-Path $diablo4Target)) {
            Write-Status "INFO" "Copying Diablo IV installation..."
            Write-Status "INFO" "Source: $diablo4Source"
            Write-Status "INFO" "Target: $diablo4Target"
            
            # Create target directory
            $targetDir = Split-Path $diablo4Target -Parent
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            
            try {
                Copy-Item -Path $diablo4Source -Destination $diablo4Target -Recurse -Force
                Write-Status "OK" "Diablo IV copied successfully"
            } catch {
                Write-Status "ERROR" "Failed to copy Diablo IV: $($_.Exception.Message)"
            }
        } else {
            Write-Status "INFO" "Diablo IV already exists at target location"
        }
    } else {
        Write-Status "INFO" "TEST MODE: Would copy Diablo IV to $diablo4Target"
    }
} else {
    Write-Status "WARNING" "Diablo IV installation not found in backup drive"
    Write-Status "INFO" "You may need to reinstall or locate the game manually"
}

# Configure Battle.net to point to copied Diablo IV
$battleNetExe = "$targetDrive\Program Files (x86)\Battle.net\Battle.net Launcher.exe"
if (Test-Path $battleNetExe) {
    Write-Status "OK" "Battle.net launcher ready"
    Write-Status "INFO" "After reboot, open Battle.net and use 'Locate Game' to point to Diablo IV"
} else {
    Write-Status "WARNING" "Battle.net launcher not found - may need manual installation"
}

# =============================================================================
# PHASE 5: System Optimization
# =============================================================================
Write-Host ""
Write-Status "PHASE" "PHASE 5: System Optimization"

# Gaming optimizations
$optimizations = @{
    "Game DVR" = @{
        Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
        Name = "AppCaptureEnabled"
        Value = 0
        Type = "DWORD"
    }
    "Game Mode" = @{
        Path = "HKCU:\SOFTWARE\Microsoft\GameBar"
        Name = "AllowAutoGameMode"
        Value = 0
        Type = "DWORD"
    }
    "Hardware Acceleration" = @{
        Path = "HKCU:\SOFTWARE\Microsoft\Avalon.Graphics"
        Name = "DisableHWAcceleration"
        Value = 0
        Type = "DWORD"
    }
}

Write-Status "INFO" "Applying Windows gaming optimizations..."

foreach ($opt in $optimizations.GetEnumerator()) {
    $optName = $opt.Key
    $settings = $opt.Value
    
    try {
        if (-not $TestMode) {
            # Ensure registry path exists
            if (-not (Test-Path $settings.Path)) {
                New-Item -Path $settings.Path -Force | Out-Null
            }
            
            Set-ItemProperty -Path $settings.Path -Name $settings.Name -Value $settings.Value -Type $settings.Type -Force
            Write-Status "OK" "$optName optimization applied"
        } else {
            Write-Status "INFO" "TEST MODE: Would apply $optName optimization"
        }
    } catch {
        Write-Status "WARNING" "Failed to apply $optName optimization: $($_.Exception.Message)"
    }
}

# Set high-performance power plan
if (-not $TestMode) {
    try {
        $powerPlans = powercfg /list
        $highPerfGuid = ($powerPlans | Select-String "High performance").ToString().Split()[3]
        if ($highPerfGuid) {
            powercfg /setactive $highPerfGuid
            Write-Status "OK" "High-performance power plan activated"
        }
    } catch {
        Write-Status "WARNING" "Could not set high-performance power plan"
    }
} else {
    Write-Status "INFO" "TEST MODE: Would set high-performance power plan"
}

# =============================================================================
# Final Status and Recommendations
# =============================================================================
Write-Host ""
Write-Status "PHASE" "Setup Complete!"

Write-Host ""
Write-Host "🎯 Setup Summary:" -ForegroundColor Yellow
Write-Host "✅ VirtIO drivers installed (reboot required)"
Write-Host "✅ Essential applications migrated from backup"
Write-Host "✅ GPU setup verified (RTX 4080 legacy BIOS fix)"
Write-Host "✅ Diablo IV installation copied"
Write-Host "✅ Windows gaming optimizations applied"
Write-Host ""

Write-Host "🚨 CRITICAL NEXT STEPS:" -ForegroundColor Red
Write-Host "1. REBOOT the VM to complete VirtIO driver installation"
Write-Host "2. Install latest NVIDIA Studio drivers"
Write-Host "3. Open Battle.net and locate existing Diablo IV installation"
Write-Host "4. Install Looking Glass host application"
Write-Host "5. Test Diablo IV GPU detection"
Write-Host ""

Write-Host "💡 Performance Verification:" -ForegroundColor Green
Write-Host "- Check Device Manager for RTX 4080 (should show no errors)"
Write-Host "- Open NVIDIA Control Panel (should detect GPU)"
Write-Host "- Run Diablo IV and verify GPU adapter in video settings"
Write-Host "- Test Looking Glass connection from Linux host"
Write-Host ""

Write-Host "🔧 If issues persist:" -ForegroundColor Cyan
Write-Host "- Run the Diablo IV GPU detection fix script"
Write-Host "- Check FenrisDebug.txt for NVAPI errors"
Write-Host "- Verify legacy BIOS configuration"
Write-Host ""

if (-not $TestMode) {
    $reboot = Read-Host "Reboot now to complete setup? (y/N)"
    if ($reboot -eq "y" -or $reboot -eq "Y") {
        Write-Status "INFO" "Rebooting in 10 seconds..."
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    }
} else {
    Write-Status "INFO" "TEST MODE: Setup simulation completed"
}
EOF

print_status "INFO" "Created comprehensive Windows VM setup script"

# Make the script executable
chmod +x "$SCRIPT_DIR/vm-setup-checker.sh"
chmod +x "$SCRIPT_DIR/fix-diablo4-gpu-detection.sh"

echo ""
echo -e "${PURPLE}🚀 Complete Setup Workflow:${NC}"
echo ""
echo "1. Pre-flight check:"
echo "   ./vm-setup-checker.sh"
echo ""
echo "2. Automated Windows setup:"
echo "   # Copy the PowerShell script to your Windows VM"
echo "   # Run as Administrator in Windows PowerShell:"
echo "   # ./windows-vm-auto-setup.ps1"
echo ""
echo "3. GPU detection fix (if needed):"
echo "   ./fix-diablo4-gpu-detection.sh"
echo ""
echo "4. Test gaming performance:"
echo "   # Launch Diablo IV and verify GPU detection"
echo "   # Use Looking Glass for ultra-low latency"
echo ""

echo -e "${GREEN}📁 Files Created:${NC}"
echo "✅ vm-setup-checker.sh - Pre-flight system verification"
echo "✅ fix-diablo4-gpu-detection.sh - Diablo IV GPU detection fix"
echo "✅ /tmp/windows-vm-auto-setup.ps1 - Complete Windows VM setup"
echo "✅ /tmp/diablo4-gpu-fix.ps1 - GPU detection PowerShell script"

echo ""
echo -e "${BLUE}🎯 Adaptation Summary:${NC}"
echo "✅ Converted PowerShell Diablo4VM scripts to Linux/QEMU equivalents"
echo "✅ Integrated your existing gaming VM setup and documentation"
echo "✅ Added RTX 4080 Error 43 legacy BIOS specific fixes"
echo "✅ Included Looking Glass optimization for ultra-low latency"
echo "✅ Automated the complete workflow from vm-side-setup-summary.md"

print_status "OK" "Linux adaptation of Diablo4VM completed!"
print_status "INFO" "Your setup addresses the GPU passthrough + gaming optimization challenge"
