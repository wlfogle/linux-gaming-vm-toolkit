#!/bin/bash

# 🎮 Diablo IV Direct Launcher for Wine with RTX 4080 Optimizations
# Bypasses Battle.net for direct game launch with maximum performance

echo "🎮 Starting Diablo IV with RTX 4080 optimizations..."

# Wine environment
export WINEPREFIX="$HOME/.wine-diablo4"
export WINEARCH=win64

# DXVK optimizations for RTX 4080
export DXVK_ASYNC=1
export DXVK_CONFIG_FILE="$WINEPREFIX/dxvk.conf"
export DXVK_LOG_LEVEL=none
export DXVK_LOG_PATH=none

# NVIDIA driver optimizations
export __GL_THREADED_OPTIMIZATIONS=1
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
export __GL_SYNC_TO_VBLANK=0
export __GL_MaxFramesAllowed=1

# Wine performance settings
export WINEDEBUG=-all
export WINE_CPU_TOPOLOGY=20:10
export WINE_LARGE_ADDRESS_AWARE=1

# Gaming CPU optimizations
export WINE_RT_POLICY=SCHED_FIFO
export WINE_RT_PRIORITY=90

# Memory optimizations
export MALLOC_CHECK_=0
export MALLOC_PERTURB_=0

# Set high performance CPU governor
echo "⚡ Setting performance mode..."
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null

# Diablo IV specific GPU preferences
echo "🎯 Configuring Diablo IV GPU preferences..."
cd "$WINEPREFIX/drive_c"
WINEPREFIX="$WINEPREFIX" wine reg add "HKEY_CURRENT_USER\\Software\\Microsoft\\DirectX\\UserGpuPreferences" /v "C:\\Games\\Diablo IV\\Diablo IV.exe" /t REG_SZ /d "GpuPreference=2;" /f > /dev/null 2>&1

# Navigate to Diablo IV directory
cd "$WINEPREFIX/drive_c/Games/Diablo IV"

# Check if game exists
if [ ! -f "Diablo IV.exe" ]; then
    echo "❌ Diablo IV.exe not found!"
    echo "💡 Try launching through Battle.net first: ./launch-battlenet-wine.sh"
    exit 1
fi

# Launch Diablo IV
echo "⚔️ Launching Diablo IV..."
echo "🎮 RTX 4080 + DXVK Performance Mode Active!"

wine "Diablo IV.exe"

echo "✅ Diablo IV session complete"
