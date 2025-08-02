#!/bin/bash

# Create default network for user session libvirt

echo "🌐 Setting up default network for user session..."

# Create default network XML
cat > /tmp/default-network.xml << 'EOF'
<network>
  <name>default</name>
  <uuid>3e5c0bf5-7b64-4d3e-9e5b-8e5c0bf57b64</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr1' stp='on' delay='0'/>
  <mac address='52:54:00:12:34:56'/>
  <ip address='192.168.100.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.100.128' end='192.168.100.254'/>
    </dhcp>
  </ip>
</network>
EOF

# Define and start the network
virsh --connect qemu:///session net-define /tmp/default-network.xml
virsh --connect qemu:///session net-start default
virsh --connect qemu:///session net-autostart default

echo "✅ Default network created and started"
virsh --connect qemu:///session net-list --all

# Clean up
rm /tmp/default-network.xml
