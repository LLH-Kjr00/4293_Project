#!/bin/bash
set -e

echo "=== Starting Example Voting App Deployment ==="

# Install Docker and Docker Compose Plugin
if ! command -v docker &> /dev/null; then
    echo "[1/3] Installing Docker..."
    sudo apt-get update -qq
    sudo apt-get install -y ca-certificates curl gnupg
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y docker.io docker-compose-plugin
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo "⚠️  Logout/login later for Docker permissions. Continuing..."
fi

# Ensure Docker Compose Availability
echo "[1.5/3] Verifying Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    if docker compose version &> /dev/null; then
        echo "ℹ️  Using modern 'docker compose' (plugin)"
    else
        echo "⚠️  Installing standalone docker-compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
fi

# Clone repo
echo "[2/3] Cloning repository..."
APP_DIR="/tmp/example-voting-app"
rm -rf "$APP_DIR" 2>/dev/null || true
git clone https://github.com/dockersamples/example-voting-app "$APP_DIR"
cd "$APP_DIR"

# Deploy with explicit path
echo "[3/3] Launching services..."
docker-compose up -d --build || docker compose up -d --build

echo "
✅ Deployment Complete!
- Vote UI:    http://{YOUR-EC2-PUBLIC-IP}:8080
- Results UI: http://{YOUR-EC2-PUBLIC-IP}:8011
"