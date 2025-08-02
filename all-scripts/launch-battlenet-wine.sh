#!/bin/bash

# 🎮 Battle.net Launcher for Wine with RTX 4080 Optimizations
# Launches Battle.net with maximum gaming performance

echo "🎮 Starting Battle.net with RTX 4080 optimizations..."

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

# Memory optimizations
export MALLOC_CHECK_=0
export MALLOC_PERTURB_=0

# Set high performance CPU governor
echo "⚡ Setting performance mode..."
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null

# Navigate to Battle.net directory
cd "$WINEPREFIX/drive_c/Program Files (x86)/Battle.net"

# Launch Battle.net
echo "⚔️ Launching Battle.net..."
wine "Battle.net Launcher.exe"

echo "✅ Battle.net session complete"
