#!/bin/bash

# ===== Docker Installation Script for Ubuntu =====
# Features:
# 1. Auto-detects Ubuntu version
# 2. Validates CPU virtualization support
# 3. Configures production-ready daemon settings
# 4. Sets up non-root user access

# Exit on error and trace commands
set -eo pipefail
trap 'echo "Error at line $LINENO"' ERR

# Check root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Verify CPU virtualization support
if ! grep -q -E 'vmx|svm' /proc/cpuinfo; then
    echo "WARNING: CPU virtualization not enabled in BIOS"
    read -p "Continue anyway? (y/N) " -n 1 -r
    [[ $REPLY =~ ^[Yy]$ ]] || exit 1
fi

# Remove old Docker versions
apt-get remove -y docker docker-engine docker.io containerd runc || true

# Install dependencies
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up stable repository
echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# Install Docker Engine
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Configure Docker daemon
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "live-restore": true
}
EOF

# Enable and start Docker
systemctl enable --now docker

# Add user to docker group (replace $USER with target username)
usermod -aG docker $SUDO_USER

echo "=== Installation Complete ==="
echo "1. Log out and back in for group permissions"
echo "2. Verify with: docker run hello-world"
