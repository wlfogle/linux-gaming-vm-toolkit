#!/bin/bash

# Windows 11 ISO Modifier for Local Account Installation
# This script modifies a Windows 11 ISO to bypass Microsoft account requirements

set -e

# Configuration
ORIGINAL_ISO="/home/lou/Downloads/Win11_24H2_English_x64.iso"
MODIFIED_ISO="/home/lou/Downloads/Win11_24H2_LocalAccount_x64.iso"
WORK_DIR="/tmp/win11_mod"
MOUNT_DIR="/tmp/win11_mount"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error "This script should NOT be run as root for security reasons"
    exit 1
fi

# Check dependencies
check_dependencies() {
    log "Checking dependencies..."
    
    local deps=("genisoimage" "7z" "xmlstarlet")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing dependencies: ${missing[*]}"
        log "Install with: sudo pacman -S cdrtools p7zip xmlstarlet"
        exit 1
    fi
}

# Clean up previous work
cleanup() {
    log "Cleaning up previous work..."
    sudo umount "$MOUNT_DIR" 2>/dev/null || true
    rm -rf "$WORK_DIR" "$MOUNT_DIR"
    mkdir -p "$WORK_DIR" "$MOUNT_DIR"
}

# Extract ISO contents
extract_iso() {
    log "Extracting ISO contents..."
    
    # Mount original ISO
    sudo mount -o loop "$ORIGINAL_ISO" "$MOUNT_DIR"
    
    # Copy all contents to work directory
    cp -r "$MOUNT_DIR"/* "$WORK_DIR"/
    
    # Unmount original ISO
    sudo umount "$MOUNT_DIR"
    
    # Make work directory writable
    chmod -R u+w "$WORK_DIR"
}

# Create autounattend.xml for local account setup
create_autounattend() {
    log "Creating autounattend.xml for local account setup..."
    
    cat > "$WORK_DIR/autounattend.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SetupUILanguage>
                <UILanguage>en-US</UILanguage>
            </SetupUILanguage>
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <UserData>
                <AcceptEula>true</AcceptEula>
            </UserData>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Home</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
                <SkipUserOOBE>true</SkipUserOOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
            </OOBE>
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Password>
                            <Value></Value>
                            <PlainText>true</PlainText>
                        </Password>
                        <Description>Local Administrator Account</Description>
                        <DisplayName>Admin</DisplayName>
                        <Group>Administrators</Group>
                        <Name>Admin</Name>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <AutoLogon>
                <Password>
                    <Value></Value>
                    <PlainText>true</PlainText>
                </Password>
                <Enabled>true</Enabled>
                <LogonCount>1</LogonCount>
                <Username>Admin</Username>
            </AutoLogon>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
    </settings>
</unattend>
EOF
}

# Create registry bypass script
create_bypass_script() {
    log "Creating Microsoft account bypass script..."
    
    mkdir -p "$WORK_DIR/sources/\$OEM\$/\$\$Setup/Scripts"
    
    cat > "$WORK_DIR/sources/\$OEM\$/\$\$Setup/Scripts/SetupComplete.cmd" << 'EOF'
@echo off
:: Disable Microsoft Account requirement
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f

:: Disable network requirement during OOBE
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State" /v ImageState /t REG_SZ /d "IMAGE_STATE_COMPLETE" /f

:: Enable local account option
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\OOBE" /v NetworkRequired /t REG_DWORD /d 0 /f

:: Disable Windows Updates during OOBE
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v NoAutoUpdate /t REG_DWORD /d 1 /f

:: Create local user account if not exists
net user LocalUser /add /fullname:"Local User" /comment:"Local Account" /passwordreq:no
net localgroup administrators LocalUser /add

echo Setup complete. Local account bypass enabled.
EOF
}

# Modify install.wim to include registry changes
modify_install_wim() {
    log "Modifying install.wim for local account support..."
    
    local wim_file="$WORK_DIR/sources/install.wim"
    local temp_mount="/tmp/wim_mount"
    
    # Create mount directory
    mkdir -p "$temp_mount"
    
    # Check if wimlib-imagex is available
    if command -v wimlib-imagex &> /dev/null; then
        log "Using wimlib-imagex for WIM modification..."
        
        # Mount the WIM file (assuming Windows 11 Pro is image 6)
        wimlib-imagex mount "$wim_file" 6 "$temp_mount"
        
        # Add registry entries to SOFTWARE hive
        if [[ -f "$temp_mount/Windows/System32/config/SOFTWARE" ]]; then
            log "Adding registry bypasses to SOFTWARE hive..."
            
            # Create a temporary registry file
            cat > /tmp/bypass.reg << 'REGEOF'
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE]
"BypassNRO"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\OOBE]
"BypassNRO"=dword:00000001
"NetworkRequired"=dword:00000000
REGEOF
        fi
        
        # Copy the autounattend.xml to the root
        cp "$WORK_DIR/autounattend.xml" "$temp_mount/"
        
        # Unmount and commit changes
        wimlib-imagex unmount "$temp_mount" --commit
        
    else
        warn "wimlib-imagex not found. Registry modifications skipped."
        log "Install with: sudo pacman -S wimlib"
    fi
}

# Create new ISO
create_iso() {
    log "Creating modified ISO..."
    
    # Create the new ISO with proper Windows boot structure
    genisoimage -b "boot/etfsboot.com" -no-emul-boot -boot-load-size 8 \
        -boot-info-table -eltorito-alt-boot -b "efi/microsoft/boot/efisys.bin" \
        -no-emul-boot -boot-load-size 1 -udf -iso-level 3 \
        -volid "WIN11_LOCAL" -o "$MODIFIED_ISO" "$WORK_DIR"
    
    log "Modified ISO created: $MODIFIED_ISO"
}

# Main execution
main() {
    log "Starting Windows 11 ISO modification for local account installation..."
    
    # Check if original ISO exists
    if [[ ! -f "$ORIGINAL_ISO" ]]; then
        error "Original ISO not found: $ORIGINAL_ISO"
        exit 1
    fi
    
    check_dependencies
    cleanup
    extract_iso
    create_autounattend
    create_bypass_script
    modify_install_wim
    create_iso
    
    log "Windows 11 ISO modification completed successfully!"
    log "Modified ISO: $MODIFIED_ISO"
    log ""
    log "Installation notes:"
    log "- This ISO will create a local 'Admin' account with no password"
    log "- Microsoft account requirement is bypassed"
    log "- Network setup is skipped during OOBE"
    log "- You can change the account name and add password after installation"
    log ""
    log "To use this ISO with your VM:"
    log "virt-install --name win11-local --ram 4096 --disk path=/home/lou/VMs/win11-local.qcow2,size=50 --cdrom $MODIFIED_ISO --os-variant win11 --graphics spice --boot uefi"
}

# Run main function
main "$@"
