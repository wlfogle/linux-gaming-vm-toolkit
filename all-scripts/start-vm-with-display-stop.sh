#!/bin/bash

echo "🎮 Starting Gaming VM with Display Manager Control"
echo "=================================================="

# Warn user about display stopping
echo "⚠️  WARNING: This will temporarily stop your desktop!"
echo "📱 Save any work and close applications before continuing."
echo "🔄 Your desktop will restart automatically after VM shutdown."
echo ""
read -p "🤔 Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted by user"
    exit 1
fi

echo "💾 Stopping display manager..."
sudo systemctl stop sddm

echo "🎯 Starting VM setup..."
~/Scripts/start-gaming-vm.sh

echo "🔄 VM has been started or script completed"
echo "🖥️  Restarting display manager..."
sudo systemctl start sddm

echo "✅ Display manager restarted"
echo "💡 You can now switch back to your desktop (Ctrl+Alt+F1)"
