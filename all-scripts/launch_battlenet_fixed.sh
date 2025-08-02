#!/bin/bash
# Fixed Battle.net Launcher for Wine with CEF crash prevention

set -e

WINE_PREFIX="$HOME/.wine-diablo4"
BATTLENET_PATH="$WINE_PREFIX/drive_c/Program Files (x86)/Battle.net/Battle.net.exe"

echo "🎮 Launching Battle.net with Wine configuration fixes..."

# Set Wine prefix
export WINEPREFIX="$WINE_PREFIX"

# Source the environment fixes if available
if [ -f "$WINE_PREFIX/launch_env.sh" ]; then
    echo "Loading Wine environment fixes..."
    source "$WINE_PREFIX/launch_env.sh"
else
    echo "⚠️  Environment fixes not found. Run fix_wine_diablo4.sh first."
    
    # Apply basic fixes inline
    export WINE_EXPERIMENTAL_WOW64=0
    export WINE_DISABLE_EXPERIMENTAL=1
    export LIBGL_ALWAYS_SOFTWARE=0
    export LIBGL_ALWAYS_INDIRECT=0
    export __GL_SHADER_DISK_CACHE=1
    export __GL_THREADED_OPTIMIZATIONS=1
    export WINEDEBUG=-all,+dll,+heap
fi

# Additional runtime fixes for CEF
export CEF_COMMAND_LINE_ARGS="--disable-gpu --disable-gpu-compositing --disable-gpu-rasterization --disable-gpu-sandbox --use-gl=desktop --disable-web-security"

# Check if Battle.net exists
if [ ! -f "$BATTLENET_PATH" ]; then
    echo "❌ Battle.net not found at: $BATTLENET_PATH"
    echo "Please ensure Battle.net is properly installed in the Wine prefix."
    exit 1
fi

echo "🚀 Starting Battle.net..."
echo "📍 Using Wine prefix: $WINE_PREFIX"
echo "🎯 Executable: $BATTLENET_PATH"
echo ""

# Clear any existing Battle.net processes
pkill -f "Battle.net" 2>/dev/null || true
pkill -f "Blizzard" 2>/dev/null || true

# Wait a moment for cleanup
sleep 2

# Launch Battle.net with CEF fixes
cd "$WINE_PREFIX/drive_c/Program Files (x86)/Battle.net/"
wine "$BATTLENET_PATH" \
    --disable-gpu \
    --disable-gpu-compositing \
    --disable-gpu-rasterization \
    --disable-gpu-sandbox \
    --use-gl=desktop \
    --disable-web-security \
    --disable-software-rasterizer 2>&1 | tee /tmp/battlenet_launch.log

echo ""
echo "✅ Battle.net launch completed."
echo "📄 Launch log saved to: /tmp/battlenet_launch.log"
