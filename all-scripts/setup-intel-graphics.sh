#!/bin/bash

echo "🔧 Setting up Intel Graphics for Desktop (NVIDIA for VM)"
echo "=========================================================="

# Check if both GPUs are available
echo "🔍 Checking available GPUs..."
INTEL_GPU=$(lspci | grep -i "intel.*graphics\|intel.*vga" | head -1)
NVIDIA_GPU=$(lspci | grep -i "nvidia.*vga\|nvidia.*graphics\|nvidia.*controller" | head -1)

if [ -z "$INTEL_GPU" ]; then
    echo "❌ Intel GPU not found! Cannot proceed."
    exit 1
fi

if [ -z "$NVIDIA_GPU" ]; then
    echo "❌ NVIDIA GPU not found!"
    exit 1
fi

echo "✅ Found Intel GPU: $INTEL_GPU"
echo "✅ Found NVIDIA GPU: $NVIDIA_GPU"
echo ""

# Create X11 configuration to prefer Intel graphics
echo "📝 Creating X11 configuration..."

sudo mkdir -p /etc/X11/xorg.conf.d

cat << 'EOF' | sudo tee /etc/X11/xorg.conf.d/20-intel-graphics.conf > /dev/null
# Force Intel graphics for desktop (leave NVIDIA for VM passthrough)
Section "Device"
    Identifier "Intel Graphics"
    Driver "modesetting"
    BusID "PCI:0:2:0"
    Option "DRI" "3"
    Option "AccelMethod" "glamor"
    Option "TearFree" "true"
EndSection

Section "Screen"
    Identifier "Intel Screen"
    Device "Intel Graphics"
EndSection

# Prevent NVIDIA from being used by X11
Section "Device"
    Identifier "NVIDIA Graphics"
    Driver "nvidia"
    BusID "PCI:2:0:0"
    Option "UseDisplayDevice" "none"
EndSection
EOF

echo "✅ Created /etc/X11/xorg.conf.d/20-intel-graphics.conf"

# Create a script to switch graphics on demand
cat << 'EOF' > /home/lou/Scripts/switch-to-intel.sh
#!/bin/bash
echo "🔄 Switching to Intel graphics..."
xrandr --setprovideroutputsource 1 0
xrandr --auto
echo "✅ Switched to Intel graphics for current session"
EOF

chmod +x /home/lou/Scripts/switch-to-intel.sh

cat << 'EOF' > /home/lou/Scripts/switch-to-nvidia.sh
#!/bin/bash
echo "🔄 Switching to NVIDIA graphics..."
xrandr --setprovideroutputsource 0 1
xrandr --auto
echo "✅ Switched to NVIDIA graphics for current session"
EOF

chmod +x /home/lou/Scripts/switch-to-nvidia.sh

echo "✅ Created graphics switching scripts"
echo ""

# Check current GPU usage
echo "📊 Current GPU status:"
echo "Desktop processes using NVIDIA:"
if sudo lsof /dev/nvidia* > /dev/null 2>&1; then
    echo "⚠️  NVIDIA GPU is currently in use by desktop"
    sudo lsof /dev/nvidia* 2>/dev/null | grep -v WARNING | head -5
else
    echo "✅ NVIDIA GPU is free for VM use"
fi

echo ""
echo "🎯 Next steps:"
echo "1. Reboot your system for X11 changes to take effect"
echo "2. After reboot, your desktop should use Intel graphics"
echo "3. Then your VM start script should work without issues"
echo ""
echo "💡 Alternative quick fix (for this session only):"
echo "   Run: ~/Scripts/switch-to-intel.sh"
echo "   Then try your VM script again"
echo ""
echo "🔧 Manual option if needed:"
echo "   1. Press Ctrl+Alt+F3 (switch to TTY)"
echo "   2. Login and run: sudo systemctl stop sddm"
echo "   3. Run your VM script: ~/Scripts/start-gaming-vm.sh"
echo "   4. After VM use: sudo systemctl start sddm"
echo "   5. Press Ctrl+Alt+F1 to return to desktop"
