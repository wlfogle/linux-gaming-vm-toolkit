#!/bin/bash
echo "🔄 Switching to Intel graphics..."
xrandr --setprovideroutputsource 1 0
xrandr --auto
echo "✅ Switched to Intel graphics for current session"
