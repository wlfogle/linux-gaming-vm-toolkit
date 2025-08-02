#!/bin/bash

# Cluster setup automation script

set -e

CLUSTER_MASTER="192.168.0.64"
NEW_NODE="192.168.0.65"
CLUSTER_NAME="homelab-cluster"

echo "🏗️  Proxmox Cluster Setup Script"
echo "================================="

echo "📋 Cluster Configuration:"
echo "   Master Node: $CLUSTER_MASTER"
echo "   New Node: $NEW_NODE"
echo "   Cluster Name: $CLUSTER_NAME"
echo ""

echo "🔧 Prerequisites Check:"
echo "1. Proxmox VE installed on VM with IP $NEW_NODE"
echo "2. Network connectivity between nodes"
echo "3. Both nodes have unique hostnames"
echo ""

echo "📡 Testing connectivity..."
ping -c 2 "$CLUSTER_MASTER" && echo "✅ Master node reachable"
ping -c 2 "$NEW_NODE" 2>/dev/null && echo "✅ New node reachable" || echo "⚠️  New node not yet reachable"

echo ""
echo "🏗️  Step 1: Create cluster on master node"
echo "SSH to $CLUSTER_MASTER and run:"
echo "pvecm create $CLUSTER_NAME"
echo ""
echo "📋 To execute automatically:"
echo "ssh root@$CLUSTER_MASTER \"pvecm create $CLUSTER_NAME\""
echo ""

echo "🔗 Step 2: Join new node to cluster"
echo "SSH to $NEW_NODE and run:"
echo "pvecm add $CLUSTER_MASTER"
echo ""
echo "📋 To execute automatically:"
echo "ssh root@$NEW_NODE \"pvecm add $CLUSTER_MASTER\""
echo ""

echo "✅ Step 3: Verify cluster"
echo "On either node, run:"
echo "pvecm status"
echo "pvecm nodes"
echo ""

echo "🌐 Web Access:"
echo "   Master: https://$CLUSTER_MASTER:8006"
echo "   New Node: https://$NEW_NODE:8006"
echo "   (Both will show the same cluster)"

echo ""
echo "💡 Troubleshooting:"
echo "   - Ensure SSH keys are set up between nodes"
echo "   - Check firewall settings (ports 22, 8006, 5404-5412)"
echo "   - Verify hostname resolution"
echo "   - Check time synchronization"
