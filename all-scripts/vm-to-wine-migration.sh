#!/bin/bash

# 🎮 Enhanced VM to Wine Migration Script for Diablo IV
# Optimized for RTX 4080 + Garuda Linux + DXVK performance
# AI-enhanced with modern Wine/gaming optimizations

set -euo pipefail

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

# Configuration
WINE_PREFIX="$HOME/.wine-diablo4"
VM_BACKUP="/var/lib/libvirt/images/win10-gaming-uefi-backup.qcow2"
TEMP_MOUNT="/tmp/vm-mount"

log "🎮 VM to Wine Migration for Diablo IV"
log "======================================"

# Step 1: Install Wine and dependencies
install_wine() {
    log "📦 Installing Wine and dependencies..."
    
    sudo pacman -S --needed wine wine-mono wine-gecko winetricks
    
    # Install additional dependencies for Battle.net
    sudo pacman -S --needed lib32-gnutls lib32-libldap lib32-libgpg-error lib32-sqlite lib32-libpulse
    
    log "✅ Wine and dependencies installed"
}

# Step 2: Create optimized Wine prefix
create_wine_prefix() {
    log "🍷 Creating optimized Wine prefix..."
    
    # Remove existing prefix if it exists
    if [ -d "$WINE_PREFIX" ]; then
        warn "Removing existing Wine prefix..."
        rm -rf "$WINE_PREFIX"
    fi
    
    # Set Wine environment
    export WINEPREFIX="$WINE_PREFIX"
    export WINEARCH=win64
    
    # Initialize Wine prefix
    log "Initializing Wine prefix with Windows 10 compatibility..."
    winecfg &
    sleep 5
    pkill winecfg
    
    # Configure Wine for gaming
    log "Configuring Wine for optimal gaming performance..."
    winetricks corefonts vcrun2019 dxvk
    
    # Set Windows 10 compatibility
    winetricks win10
    
    log "✅ Wine prefix created and configured"
}

# Step 3: Mount VM and extract applications
extract_vm_content() {
    log "💾 Mounting VM backup to extract applications..."
    
    # Load NBD module
    sudo modprobe nbd max_part=8
    
    # Connect VM image
    sudo qemu-nbd --connect=/dev/nbd0 "$VM_BACKUP"
    
    # Create mount point
    sudo mkdir -p "$TEMP_MOUNT"
    
    # Mount Windows partition (usually partition 3 on UEFI systems)
    sudo mount /dev/nbd0p3 "$TEMP_MOUNT"
    
    log "✅ VM backup mounted at $TEMP_MOUNT"
}

# Step 4: Copy Battle.net
copy_battlenet() {
    log "⚔️ Copying Battle.net installation..."
    
    BATTLENET_SRC="$TEMP_MOUNT/Program Files (x86)/Battle.net"
    BATTLENET_DST="$WINE_PREFIX/drive_c/Program Files (x86)/Battle.net"
    
    if [ -d "$BATTLENET_SRC" ]; then
        mkdir -p "$(dirname "$BATTLENET_DST")"
        cp -r "$BATTLENET_SRC" "$BATTLENET_DST"
        log "✅ Battle.net copied to Wine prefix"
    else
        warn "Battle.net not found in VM backup"
    fi
}

# Step 5: Copy Diablo IV
copy_diablo4() {
    log "🎮 Searching for Diablo IV installation..."
    
    # Search for Diablo IV in common locations
    DIABLO_LOCATIONS=(
        "$TEMP_MOUNT/Games/Diablo IV"
        "$TEMP_MOUNT/Program Files (x86)/Diablo IV"
        "$TEMP_MOUNT/Program Files/Diablo IV"
    )
    
    for location in "${DIABLO_LOCATIONS[@]}"; do
        if [ -d "$location" ]; then
            log "Found Diablo IV at: $location"
            DIABLO_DST="$WINE_PREFIX/drive_c/Games/Diablo IV"
            mkdir -p "$(dirname "$DIABLO_DST")"
            cp -r "$location" "$DIABLO_DST"
            log "✅ Diablo IV copied to Wine prefix"
            return
        fi
    done
    
    warn "Diablo IV installation not found in VM backup"
}

# Step 6: Copy Windows registry and settings
copy_registry() {
    log "📋 Copying Windows registry and settings..."
    
    # Copy user registry files
    USER_REG_SRC="$TEMP_MOUNT/Users/*/NTUSER.DAT"
    if ls $USER_REG_SRC 1> /dev/null 2>&1; then
        # Convert Windows registry to Wine format (simplified)
        log "Registry found - manual import may be needed"
    fi
    
    # Copy important application data
    APPDATA_SRC="$TEMP_MOUNT/Users/*/AppData"
    if [ -d "$APPDATA_SRC" ]; then
        APPDATA_DST="$WINE_PREFIX/drive_c/users/$(whoami)/AppData"
        mkdir -p "$APPDATA_DST"
        
        # Copy Battle.net and Blizzard data
        if [ -d "$APPDATA_SRC/Roaming/Battle.net" ]; then
            cp -r "$APPDATA_SRC/Roaming/Battle.net" "$APPDATA_DST/Roaming/"
        fi
        
        if [ -d "$APPDATA_SRC/Local/Blizzard Entertainment" ]; then
            cp -r "$APPDATA_SRC/Local/Blizzard Entertainment" "$APPDATA_DST/Local/"
        fi
        
        log "✅ Application data copied"
    fi
}

# Step 7: Install Visual C++ redistributables and .NET
install_dependencies() {
    log "📚 Installing Windows dependencies in Wine..."
    
    export WINEPREFIX="$WINE_PREFIX"
    
    # Install common gaming dependencies
    winetricks vcrun2019 vcrun2017 vcrun2015 vcrun2013 vcrun2012 vcrun2010 vcrun2008 vcrun2005
    winetricks dotnet48 dotnetcore3 dotnet6
    
    # Install DirectX and gaming libraries
    winetricks d3dx9 d3dx10 d3dx11_43 dxvk
    
    log "✅ Dependencies installed"
}

# Step 8: Configure Wine for Battle.net
configure_battlenet() {
    log "⚔️ Configuring Wine for Battle.net compatibility..."
    
    export WINEPREFIX="$WINE_PREFIX"
    
    # Disable crash dialogs
    winetricks nocrashdialog
    
    # Set up DLL overrides for Battle.net
    wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "msvcp140" /t REG_SZ /d "native,builtin" /f
    wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "vcruntime140" /t REG_SZ /d "native,builtin" /f
    wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "api-ms-win-crt-runtime-l1-1-0" /t REG_SZ /d "native,builtin" /f
    
    log "✅ Battle.net compatibility configured"
}

# Step 8.5: RTX 4080 DXVK Optimizations
configure_rtx_optimizations() {
    log "🎮 Configuring RTX 4080 DXVK optimizations..."
    
    export WINEPREFIX="$WINE_PREFIX"
    
    # DXVK configuration for RTX 4080
    cat > "$WINE_PREFIX/dxvk.conf" << 'DXVKEOF'
# RTX 4080 Optimized DXVK Configuration
dxvk.enableAsync = true
dxvk.numCompilerThreads = 0
dxvk.maxFrameLatency = 1
dxvk.tearFree = false
dxvk.syncInterval = 0
dxvk.maxDeviceMemory = 12288
dxvk.maxSharedMemory = 2048
dxvk.useRawSsbo = true
dxvk.hud = fps,memory,gpu
DXVKEOF
    
    # Environment optimizations for gaming
    cat > "$WINE_PREFIX/gaming_env.sh" << 'ENVEOF'
#!/bin/bash
# RTX 4080 Gaming Environment Variables

# DXVK Optimizations
export DXVK_ASYNC=1
export DXVK_CONFIG_FILE="$WINEPREFIX/dxvk.conf"
export DXVK_LOG_LEVEL=none
export DXVK_LOG_PATH=none

# NVIDIA Driver Optimizations
export __GL_THREADED_OPTIMIZATIONS=1
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
export __GL_SYNC_TO_VBLANK=0
export __GL_MaxFramesAllowed=1

# Wine Performance
export WINEDEBUG=-all
export WINE_CPU_TOPOLOGY=20:10
export WINE_LARGE_ADDRESS_AWARE=1

# Gaming CPU Optimizations
export WINE_RT_POLICY=SCHED_FIFO
export WINE_RT_PRIORITY=90

# Memory optimizations
export MALLOC_CHECK_=0
export MALLOC_PERTURB_=0
ENVEOF
    
    chmod +x "$WINE_PREFIX/gaming_env.sh"
    
    log "✅ RTX 4080 optimizations configured"
}

# Step 8.6: Configure Diablo IV specific optimizations
configure_diablo4_optimizations() {
    log "🎯 Configuring Diablo IV specific optimizations..."
    
    export WINEPREFIX="$WINE_PREFIX"
    
    # Create Diablo IV specific configuration
    mkdir -p "$WINE_PREFIX/drive_c/users/$(whoami)/Documents/Diablo IV"
    
    # GPU preference registry entries
    wine reg add "HKEY_CURRENT_USER\Software\Microsoft\DirectX\UserGpuPreferences" /v "C:\Games\Diablo IV\Diablo IV.exe" /t REG_SZ /d "GpuPreference=2;" /f
    
    # Diablo IV performance settings
    wine reg add "HKEY_CURRENT_USER\Software\Blizzard Entertainment\Diablo IV" /v "GraphicsAdapter" /t REG_DWORD /d 0 /f
    wine reg add "HKEY_CURRENT_USER\Software\Blizzard Entertainment\Diablo IV" /v "WindowMode" /t REG_DWORD /d 1 /f
    wine reg add "HKEY_CURRENT_USER\Software\Blizzard Entertainment\Diablo IV" /v "VSync" /t REG_DWORD /d 0 /f
    
    # Disable Windows Gaming features that can interfere
    wine reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f
    wine reg add "HKEY_CURRENT_USER\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 0 /f
    
    log "✅ Diablo IV optimizations configured"
}

# Step 9: Cleanup
cleanup() {
    log "🧹 Cleaning up..."
    
    sudo umount "$TEMP_MOUNT" 2>/dev/null || true
    sudo qemu-nbd --disconnect /dev/nbd0 2>/dev/null || true
    sudo rmdir "$TEMP_MOUNT" 2>/dev/null || true
    
    log "✅ Cleanup completed"
}

# Step 10: Create launch scripts
create_launch_scripts() {
    log "🚀 Creating launch scripts..."
    
    # Battle.net launcher script
    cat > "$HOME/Scripts/launch-battlenet-wine.sh" << 'EOF'
#!/bin/bash
export WINEPREFIX="$HOME/.wine-diablo4"
export WINEDEBUG=-all
export DXVK_LOG_LEVEL=none

cd "$WINEPREFIX/drive_c/Program Files (x86)/Battle.net"
wine "Battle.net Launcher.exe"
EOF

    # Diablo IV direct launch script
    cat > "$HOME/Scripts/launch-diablo4-wine.sh" << 'EOF'
#!/bin/bash
export WINEPREFIX="$HOME/.wine-diablo4"
export WINEDEBUG=-all
export DXVK_LOG_LEVEL=none

cd "$WINEPREFIX/drive_c/Games/Diablo IV"
wine "Diablo IV.exe"
EOF

    chmod +x "$HOME/Scripts/launch-battlenet-wine.sh"
    chmod +x "$HOME/Scripts/launch-diablo4-wine.sh"
    
    log "✅ Launch scripts created"
}

# Main execution
main() {
    log "Starting VM to Wine migration process..."
    
    # Check if VM backup exists
    if [ ! -f "$VM_BACKUP" ]; then
        error "VM backup not found at $VM_BACKUP"
        exit 1
    fi
    
    # Check if running as user (not root)
    if [ "$EUID" -eq 0 ]; then
        error "Do not run this script as root"
        exit 1
    fi
    
    install_wine
    create_wine_prefix
    extract_vm_content
    copy_battlenet
    copy_diablo4
    copy_registry
    install_dependencies
    configure_battlenet
    configure_rtx_optimizations
    configure_diablo4_optimizations
    create_launch_scripts
    cleanup
    
    log "🎮 VM to Wine migration completed!"
    log ""
    log "🚀 To launch Battle.net: $HOME/Scripts/launch-battlenet-wine.sh"
    log "🎯 To launch Diablo IV: $HOME/Scripts/launch-diablo4-wine.sh"
    log ""
    log "🍷 Wine prefix location: $WINE_PREFIX"
    log ""
    log "💡 If you encounter issues:"
    log "   - Run winecfg to adjust compatibility settings"
    log "   - Check Wine logs for errors"
    log "   - Battle.net login should work since it's using VM configuration"
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

main "$@"
