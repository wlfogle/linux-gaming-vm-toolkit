#!/bin/bash

# Fix Proxmox SSL Certificate Issues
# Helps with self-signed certificate warnings

set -e

echo "🔒 Proxmox SSL Certificate Helper"
echo "================================="

echo ""
echo "🌐 Browser Access Options:"
echo ""
echo "1. 🦊 Firefox/FireDragon - Manual SSL Exception:"
echo "   - Go to https://192.168.0.64:8006"
echo "   - Click 'Advanced'"
echo "   - Click 'Accept the Risk and Continue'"
echo ""
echo "2. 🅾️  Opera - Using command line flags:"
echo "   pimox-web    # Opens with SSL bypass flags"
echo "   proxmox-web  # Opens with SSL bypass flags"
echo ""
echo "3. 🌍 Alternative - Direct Opera command:"
echo "   opera --ignore-certificate-errors --allow-running-insecure-content https://192.168.0.64:8006"
echo ""

echo "🔧 Current browser aliases:"
echo "   pimox-web    # Raspberry Pi Proxmox (.64) with Opera"
echo "   proxmox-web  # VM Proxmox (.65) with Opera"
echo ""

echo "📋 To manually add SSL exceptions:"
echo ""
echo "For Firefox/FireDragon:"
echo "1. Open the Proxmox URL"
echo "2. Click on the lock icon or warning"
echo "3. Add permanent exception"
echo ""
echo "For Opera:"
echo "1. Go to opera://settings/security"
echo "2. Click 'Manage certificates'"
echo "3. Go to 'Authorities' tab"
echo "4. Import the Proxmox certificate (if available)"
echo ""

echo "🚀 Testing current setup:"
echo "   Raspberry Pi Proxmox: https://192.168.0.64:8006"
ping -c 1 192.168.0.64 >/dev/null && echo "   ✅ Pi reachable" || echo "   ❌ Pi not reachable"

echo "   VM Proxmox: https://192.168.0.65:8006"
ping -c 1 192.168.0.65 >/dev/null 2>&1 && echo "   ✅ VM reachable" || echo "   ⚠️  VM not yet configured"

echo ""
echo "💡 Quick access commands:"
echo "   pimox-web     # Open Pi Proxmox in Opera (bypasses SSL)"
echo "   proxmox-web   # Open VM Proxmox in Opera (bypasses SSL)"
