#!/bin/bash
echo "🔄 Switching to NVIDIA graphics..."
xrandr --setprovideroutputsource 0 1
xrandr --auto
echo "✅ Switched to NVIDIA graphics for current session"
