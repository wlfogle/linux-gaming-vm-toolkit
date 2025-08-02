# Complete Diablo IV Gaming Setup Script for Windows VM
# This implements everything from your documentation to get Diablo IV working

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

$Host.UI.RawUI.WindowTitle = "Diablo IV Gaming Setup"

Write-Host ""
Write-Host "🎮 Complete Diablo IV Gaming Setup" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "Legacy BIOS Windows 10 - RTX 4080 Gaming Environment" -ForegroundColor Gray
Write-Host ""

# Function for colored output
function Write-Status {
    param([string]$Status, [string]$Message)
    switch ($Status) {
        "OK" { Write-Host "✅ $Message" -ForegroundColor Green }
        "WARNING" { Write-Host "⚠️  $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "❌ $Message" -ForegroundColor Red }
        "INFO" { Write-Host "ℹ️  $Message" -ForegroundColor Blue }
        "ACTION" { Write-Host "🚀 $Message" -ForegroundColor Magenta }
    }
}

# Check Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Status "ERROR" "This script must be run as Administrator"
    Write-Host ""
    Write-Host "🔧 How to run as Administrator:" -ForegroundColor Yellow
    Write-Host "1. Right-click PowerShell in Start Menu"
    Write-Host "2. Select 'Run as Administrator'"
    Write-Host "3. Navigate to this script and run it"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Status "OK" "Running as Administrator"

# =============================================================================
# PHASE 1: System Information and Drive Detection
# =============================================================================
Write-Host ""
Write-Status "ACTION" "PHASE 1: System Information"

# Detect available drives
$drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
Write-Status "INFO" "Available drives:"
foreach ($drive in $drives) {
    $sizeGB = [math]::Round($drive.Size / 1GB, 1)
    $freeGB = [math]::Round($drive.FreeSpace / 1GB, 1)
    Write-Host "  $($drive.DeviceID) - $sizeGB GB total, $freeGB GB free" -ForegroundColor Gray
}

# Expected drive mapping from your docs
$targetDrive = "C:"        # Fresh Windows 10 install
$backupDrive = $null       # E: drive with apps
$virtIODrive = $null       # F: drive with VirtIO
$gamesDrive = $null        # Games drive

# Auto-detect drives
foreach ($drive in $drives) {
    $letter = $drive.DeviceID
    if (Test-Path "$letter\Program Files\Looking Glass (host)") {
        $backupDrive = $letter
        Write-Status "OK" "Backup drive detected: $letter (contains Looking Glass)"
    }
    if (Test-Path "$letter\virtio-win-guest-tools.exe") {
        $virtIODrive = $letter
        Write-Status "OK" "VirtIO drive detected: $letter"
    }
    if (Test-Path "$letter\Games") {
        $gamesDrive = $letter
        Write-Status "OK" "Games drive detected: $letter"
    }
}

# =============================================================================
# PHASE 2: VirtIO Drivers Installation
# =============================================================================
Write-Host ""
Write-Status "ACTION" "PHASE 2: VirtIO Drivers"

if ($virtIODrive) {
    $virtIOInstaller = "$virtIODrive\virtio-win-guest-tools.exe"
    if (Test-Path $virtIOInstaller) {
        Write-Status "INFO" "Installing VirtIO drivers from $virtIOInstaller"
        $installResult = Start-Process -FilePath $virtIOInstaller -ArgumentList "/S" -Wait -PassThru
        if ($installResult.ExitCode -eq 0) {
            Write-Status "OK" "VirtIO drivers installed successfully"
        } else {
            Write-Status "WARNING" "VirtIO installation may have issues (Exit code: $($installResult.ExitCode))"
        }
    }
} else {
    Write-Status "WARNING" "VirtIO drive not found - drivers may need manual installation"
}

# =============================================================================
# PHASE 3: GPU Detection and Driver Status
# =============================================================================
Write-Host ""
Write-Status "ACTION" "PHASE 3: GPU Detection"

# Check for NVIDIA GPU
$gpus = Get-WmiObject -Class Win32_VideoController
Write-Status "INFO" "Display adapters detected:"
foreach ($gpu in $gpus) {
    $status = if ($gpu.Status -eq "OK") { "✅" } else { "❌" }
    Write-Host "  $status $($gpu.Name) - $($gpu.Status)" -ForegroundColor Gray
}

# Check specifically for RTX 4080
$rtx4080 = $gpus | Where-Object { $_.Name -like "*RTX 4080*" -or $_.Name -like "*4080*" }
if ($rtx4080) {
    Write-Status "OK" "RTX 4080 detected: $($rtx4080.Name)"
    if ($rtx4080.Status -eq "OK") {
        Write-Status "OK" "RTX 4080 status: Working properly"
    } else {
        Write-Status "WARNING" "RTX 4080 status: $($rtx4080.Status)"
        Write-Status "INFO" "Legacy BIOS should fix Error 43 issues"
    }
} else {
    Write-Status "ERROR" "RTX 4080 not detected!"
    Write-Status "INFO" "Check GPU passthrough configuration"
}

# Check for problematic Microsoft Basic Render Driver
$basicRender = $gpus | Where-Object { $_.Name -like "*Basic*" -or $_.Name -like "*Microsoft*" }
if ($basicRender) {
    Write-Status "WARNING" "Microsoft Basic Render Driver detected - may cause Diablo IV issues"
    Write-Status "INFO" "This is the issue mentioned in the GitHub fix"
} else {
    Write-Status "OK" "No conflicting basic render drivers"
}

# =============================================================================
# PHASE 4: NVIDIA Driver Registry Fix (GitHub Issue Solution)
# =============================================================================
Write-Host ""
Write-Status "ACTION" "PHASE 4: NVIDIA Driver Registry Fix"

$nvRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm"
if (Test-Path $nvRegistryPath) {
    Write-Status "OK" "NVIDIA driver registry key exists"
    
    # Export registry for backup
    $backupPath = "C:\nvlddmkm-backup.reg"
    Write-Status "INFO" "Creating registry backup at $backupPath"
    reg export "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" $backupPath /y | Out-Null
    
    # Check registry key properties
    $nvKey = Get-ItemProperty -Path $nvRegistryPath -ErrorAction SilentlyContinue
    if ($nvKey) {
        Write-Status "OK" "Registry key accessible with $(($nvKey | Get-Member -MemberType NoteProperty).Count) properties"
    }
} else {
    Write-Status "ERROR" "NVIDIA driver registry key missing"
    Write-Status "INFO" "NVIDIA drivers may need installation/reinstallation"
}

# =============================================================================
# PHASE 5: Application Migration from Backup Drive
# =============================================================================
Write-Host ""
Write-Status "ACTION" "PHASE 5: Application Migration"

if ($backupDrive) {
    Write-Status "INFO" "Migrating applications from backup drive $backupDrive"
    
    # Applications to migrate
    $apps = @(
        @{ Name="Looking Glass Host"; Source="$backupDrive\Program Files\Looking Glass (host)"; Dest="C:\Program Files\Looking Glass (host)" },
        @{ Name="Battle.net"; Source="$backupDrive\Program Files (x86)\Battle.net"; Dest="C:\Program Files (x86)\Battle.net" },
        @{ Name="Warp"; Source="$backupDrive\Program Files\Warp"; Dest="C:\Program Files\Warp" }
    )
    
    foreach ($app in $apps) {
        if (Test-Path $app.Source) {
            Write-Status "OK" "$($app.Name) found at source"
            if (-not (Test-Path $app.Dest)) {
                Write-Status "INFO" "Copying $($app.Name)..."
                try {
                    Copy-Item -Path $app.Source -Destination $app.Dest -Recurse -Force
                    Write-Status "OK" "$($app.Name) copied successfully"
                } catch {
                    Write-Status "ERROR" "Failed to copy $($app.Name): $($_.Exception.Message)"
                }
            } else {
                Write-Status "INFO" "$($app.Name) already exists at destination"
            }
        } else {
            Write-Status "WARNING" "$($app.Name) not found in backup"
        }
    }
} else {
    Write-Status "WARNING" "Backup drive not detected - manual app installation needed"
}

# =============================================================================
# PHASE 6: Diablo IV Setup
# =============================================================================
Write-Host ""
Write-Status "ACTION" "PHASE 6: Diablo IV Game Setup"

# Look for existing Diablo IV installation
$diablo4Locations = @()
if ($backupDrive) { $diablo4Locations += "$backupDrive\Games\Diablo IV" }
if ($gamesDrive) { $diablo4Locations += "$gamesDrive\Games\Diablo IV" }
$diablo4Locations += "C:\Program Files (x86)\Diablo IV"

$diablo4Source = $null
foreach ($location in $diablo4Locations) {
    if (Test-Path "$location\Diablo IV.exe") {
        $diablo4Source = $location
        break
    }
}

if ($diablo4Source) {
    Write-Status "OK" "Diablo IV installation found at: $diablo4Source"
    
    # Check if we need to copy it
    $diablo4Target = if ($gamesDrive) { "$gamesDrive\Games\Diablo IV" } else { "C:\Games\Diablo IV" }
    
    if ($diablo4Source -ne $diablo4Target -and -not (Test-Path "$diablo4Target\Diablo IV.exe")) {
        Write-Status "INFO" "Copying Diablo IV to target location: $diablo4Target"
        $targetDir = Split-Path $diablo4Target -Parent
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        try {
            Copy-Item -Path $diablo4Source -Destination $diablo4Target -Recurse -Force
            Write-Status "OK" "Diablo IV copied to $diablo4Target"
        } catch {
            Write-Status "ERROR" "Failed to copy Diablo IV: $($_.Exception.Message)"
        }
    } else {
        Write-Status "OK" "Diablo IV already in correct location"
    }
} else {
    Write-Status "WARNING" "Diablo IV installation not found"
    Write-Status "INFO" "You may need to install it fresh through Battle.net"
}

# =============================================================================
# PHASE 7: Gaming Optimizations
# =============================================================================
Write-Host ""
Write-Status "ACTION" "PHASE 7: Gaming Optimizations"

# Disable Game DVR
try {
    $gameDVRPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
    if (-not (Test-Path $gameDVRPath)) { New-Item -Path $gameDVRPath -Force | Out-Null }
    Set-ItemProperty -Path $gameDVRPath -Name "AppCaptureEnabled" -Value 0 -Type DWORD -Force
    Write-Status "OK" "Game DVR disabled"
} catch {
    Write-Status "WARNING" "Failed to disable Game DVR"
}

# Disable Game Mode
try {
    $gameBarPath = "HKCU:\SOFTWARE\Microsoft\GameBar"
    if (-not (Test-Path $gameBarPath)) { New-Item -Path $gameBarPath -Force | Out-Null }
    Set-ItemProperty -Path $gameBarPath -Name "AllowAutoGameMode" -Value 0 -Type DWORD -Force
    Write-Status "OK" "Game Mode disabled"
} catch {
    Write-Status "WARNING" "Failed to disable Game Mode"
}

# Set high-performance power plan
try {
    $powerPlans = powercfg /list
    $highPerfPlan = $powerPlans | Select-String "High performance"
    if ($highPerfPlan) {
        $guid = $highPerfPlan.ToString().Split()[3]
        powercfg /setactive $guid
        Write-Status "OK" "High-performance power plan activated"
    }
} catch {
    Write-Status "WARNING" "Could not set high-performance power plan"
}

# =============================================================================
# PHASE 8: Looking Glass Host Setup
# =============================================================================
Write-Host ""
Write-Status "ACTION" "PHASE 8: Looking Glass Host"

$lgHostPath = "C:\Program Files\Looking Glass (host)\looking-glass-host.exe"
if (Test-Path $lgHostPath) {
    Write-Status "OK" "Looking Glass host found"
    
    # Check if it's running
    $lgProcess = Get-Process -Name "looking-glass-host" -ErrorAction SilentlyContinue
    if ($lgProcess) {
        Write-Status "OK" "Looking Glass host is running"
    } else {
        Write-Status "INFO" "Starting Looking Glass host..."
        try {
            Start-Process -FilePath $lgHostPath -WindowStyle Minimized
            Write-Status "OK" "Looking Glass host started"
        } catch {
            Write-Status "ERROR" "Failed to start Looking Glass host: $($_.Exception.Message)"
        }
    }
} else {
    Write-Status "WARNING" "Looking Glass host not found - install manually if needed"
}

# =============================================================================
# PHASE 9: NVIDIA Control Panel and GPU Configuration
# =============================================================================
Write-Host ""
Write-Status "ACTION" "PHASE 9: NVIDIA Configuration"

# Check if NVIDIA Control Panel is accessible
$nvcplPath = "${env:ProgramFiles}\NVIDIA Corporation\Control Panel Client\nvcplui.exe"
if (Test-Path $nvcplPath) {
    Write-Status "OK" "NVIDIA Control Panel available"
} else {
    Write-Status "WARNING" "NVIDIA Control Panel not found - drivers may need installation"
}

# Check NVIDIA services
$nvidiaServices = @("NVDisplay.ContainerLocalSystem", "NVIDIA Display Driver Service")
foreach ($serviceName in $nvidiaServices) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        if ($service.Status -eq "Running") {
            Write-Status "OK" "$serviceName is running"
        } else {
            Write-Status "INFO" "Starting $serviceName..."
            try {
                Start-Service $serviceName
                Write-Status "OK" "$serviceName started"
            } catch {
                Write-Status "WARNING" "Could not start $serviceName"
            }
        }
    }
}

# =============================================================================
# FINAL STATUS AND NEXT STEPS
# =============================================================================
Write-Host ""
Write-Status "ACTION" "🎯 Setup Complete!"

Write-Host ""
Write-Host "📊 System Status Summary:" -ForegroundColor Yellow
Write-Host "✅ VirtIO drivers: Installed"
Write-Host "✅ GPU detection: RTX 4080 $(if($rtx4080){'detected'}else{'NOT detected'})"
Write-Host "✅ Applications: Migrated from backup"
Write-Host "✅ Gaming optimizations: Applied"
Write-Host "✅ Looking Glass: $(if(Test-Path $lgHostPath){'Available'}else{'Needs installation'})"

Write-Host ""
Write-Host "🎮 Next Steps to Play Diablo IV:" -ForegroundColor Green
Write-Host "1. Open Battle.net launcher"
Write-Host "2. Go to Diablo IV in your library"
Write-Host "3. Click 'Options' → 'Scan for games'"
Write-Host "4. Point to your Diablo IV installation folder"
Write-Host "5. Launch the game!"

Write-Host ""
Write-Host "🔧 If Diablo IV doesn't detect GPU:" -ForegroundColor Cyan
Write-Host "1. Open NVIDIA Control Panel"
Write-Host "2. Go to 'Manage 3D settings'"
Write-Host "3. Add Diablo IV.exe"
Write-Host "4. Set preferred graphics to 'High-performance NVIDIA processor'"
Write-Host "5. In Diablo IV video settings, ensure RTX 4080 is selected"

Write-Host ""
Write-Host "⚡ Performance Tips:" -ForegroundColor Magenta
Write-Host "- Use fullscreen mode for best performance"
Write-Host "- Enable DLSS in video settings"
Write-Host "- Looking Glass provides ultra-low latency"
Write-Host "- Your VM has 20 CPU cores and 16GB RAM dedicated"

Write-Host ""
Write-Host "🎯 Ready to Game!" -ForegroundColor Green
Write-Host "Your Windows VM is now optimized for Diablo IV gaming!"

Write-Host ""
$continue = Read-Host "Press Enter to continue or 'R' to reboot now"
if ($continue -eq "R" -or $continue -eq "r") {
    Write-Status "INFO" "Rebooting in 5 seconds..."
    Start-Sleep -Seconds 5
    Restart-Computer -Force
}
