#!/bin/bash

echo "=== GPU Passthrough Setup Complete ==="
echo
echo "The following changes have been made to your system:"
echo "1. ✓ X11 configured to use Intel Graphics for desktop"
echo "2. ✓ GRUB configured with VFIO kernel parameters"
echo "3. ✓ NVIDIA GPU (10de:27e0,10de:22bc) will be bound to VFIO at boot"
echo
echo "After reboot:"
echo "- Your desktop will use Intel Graphics"
echo "- NVIDIA RTX 4080 will be reserved for VM passthrough"
echo "- Your start-gaming-vm.sh script will work without unbind issues"
echo
echo "Current status:"
/home/lou/Scripts/check-vfio-setup.sh
echo
read -p "Reboot now to apply changes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting in 3 seconds..."
    sleep 3
    sudo reboot
else
    echo "Reboot cancelled. Run 'sudo reboot' when ready."
    echo "After reboot, run: ~/Scripts/check-vfio-setup.sh"
fi
