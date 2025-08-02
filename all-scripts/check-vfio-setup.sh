#!/bin/bash

echo "=== VFIO Setup Check ==="
echo

# Check if IOMMU is enabled
if grep -q "intel_iommu=on" /proc/cmdline; then
    echo "✓ IOMMU is enabled in kernel parameters"
else
    echo "✗ IOMMU is NOT enabled in kernel parameters"
fi

# Check if VFIO modules are loaded
if lsmod | grep -q vfio; then
    echo "✓ VFIO modules are loaded"
else
    echo "✗ VFIO modules are NOT loaded"
fi

# Check if NVIDIA GPU is bound to VFIO
if lspci -k | grep -A 3 "NVIDIA" | grep -q "vfio-pci"; then
    echo "✓ NVIDIA GPU is bound to VFIO-PCI driver"
else
    echo "✗ NVIDIA GPU is NOT bound to VFIO-PCI driver"
fi

# Check which driver is handling the display
echo
echo "=== Current Graphics Setup ==="
echo "Display driver in use:"
if pci_device=$(lspci | grep "VGA.*Intel"); then
    echo "✓ Intel Graphics detected for display"
    echo "  $pci_device"
else
    echo "? Intel Graphics not detected as primary display"
fi

if pci_device=$(lspci | grep "VGA.*NVIDIA"); then
    echo "NVIDIA GPU status:"
    echo "  $pci_device"
    driver=$(lspci -k | grep -A 3 "NVIDIA.*VGA" | grep "Kernel driver in use" | cut -d: -f2 | xargs)
    if [ "$driver" = "vfio-pci" ]; then
        echo "  ✓ Driver: $driver (Ready for VM passthrough)"
    else
        echo "  ✗ Driver: $driver (Not ready for VM passthrough)"
    fi
fi

echo
echo "=== IOMMU Groups ==="
echo "NVIDIA GPU IOMMU group:"
for gpu in $(lspci | grep "NVIDIA" | cut -d' ' -f1); do
    echo "  GPU $gpu: IOMMU Group $(cat /sys/bus/pci/devices/0000:$gpu/iommu_group/devices/0000:$gpu/iommu_group 2>/dev/null | wc -l) devices"
done

echo
echo "=== Summary ==="
if lspci -k | grep -A 3 "NVIDIA" | grep -q "vfio-pci"; then
    echo "🎉 System is configured correctly for GPU passthrough!"
    echo "   Your VM start script should work without unbind issues."
else
    echo "⚠️  System needs a reboot to complete VFIO setup."
    echo "   After reboot, the NVIDIA GPU will be bound to VFIO automatically."
fi
