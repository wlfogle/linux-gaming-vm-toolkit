#!/bin/bash

# 🎮 Lutris + Diablo IV Setup for Better Battle.net Support
# Uses Lutris for easier Battle.net management with automatic optimizations

echo "🎮 Setting up Lutris for Diablo IV gaming..."

# Install Lutris if not already installed
if ! command -v lutris &> /dev/null; then
    echo "📦 Installing Lutris..."
    sudo pacman -S --needed lutris
fi

# Create optimized Lutris prefix for Diablo IV
LUTRIS_PREFIX="$HOME/Games/diablo-iv"
mkdir -p "$LUTRIS_PREFIX"

# Create Lutris YAML configuration for Diablo IV
cat > "/tmp/diablo-iv-lutris.yml" << 'EOF'
game:
  exe: drive_c/Program Files (x86)/Battle.net/Battle.net Launcher.exe
  prefix: $HOME/Games/diablo-iv

system:
  env:
    DXVK_ASYNC: '1'
    DXVK_LOG_LEVEL: none
    __GL_SHADER_DISK_CACHE: '1'
    __GL_THREADED_OPTIMIZATIONS: '1'
    WINE_CPU_TOPOLOGY: '20:10'
    WINE_LARGE_ADDRESS_AWARE: '1'
  
wine:
  version: lutris-GE-Proton8-26-x86_64
  arch: win64
  Desktop: true
  WineDesktop: 1920x1080

dxvk:
  version: v2.6.2

installer:
- task:
    name: create_prefix
    prefix: $HOME/Games/diablo-iv
    arch: win64
    install_gecko: false
    install_mono: false

- task:
    name: winecfg
    prefix: $HOME/Games/diablo-iv
    setting: win10

- task:
    name: winetricks
    prefix: $HOME/Games/diablo-iv
    app: vcrun2019 dxvk corefonts

- copy:
    src: $HOME/.wine-diablo4/drive_c/Program Files (x86)/Battle.net
    dst: $HOME/Games/diablo-iv/drive_c/Program Files (x86)/Battle.net

- copy:
    src: $HOME/.wine-diablo4/drive_c/Games/Diablo IV
    dst: $HOME/Games/diablo-iv/drive_c/Games/Diablo IV

slug: diablo-iv-optimized
steamid: null
version: RTX 4080 Optimized
year: 2023
EOF

echo "✅ Lutris configuration created"
echo ""
echo "🚀 To set up Diablo IV in Lutris:"
echo "1. Open Lutris"
echo "2. Click '+' to add a game"
echo "3. Select 'Install from YAML'"
echo "4. Use the file: /tmp/diablo-iv-lutris.yml"
echo ""
echo "🎯 Alternative: Use the working Wine setup:"
echo "- Battle.net: ./launch-battlenet-wine.sh"
echo "- Diablo IV:  ./launch-diablo4-wine.sh"
