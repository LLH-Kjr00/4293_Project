#!/bin/bash

# Linux Tweet App Deployment Script
# Usage: ./deploy_tweet_app.sh [PORT] (default: 80)

set -e  # Exit on error

# Variables
PORT=${1:-80}
CONTAINER_NAME="linux_tweet_app"
REPO_URL="https://github.com/dockersamples/linux_tweet_app.git"
APP_DIR="/tmp/linux_tweet_app"

echo "=== Starting Linux Tweet App Deployment ==="

# Update system packages
echo "[1/5] Updating system packages..."
sudo apt-get update -qq

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "[2/5] Installing Docker..."
    sudo apt-get install -y docker.io
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo "⚠️  Please logout and login again for Docker group changes to take effect"
    exit 1
fi

# Clone repository
echo "[3/5] Cloning repository..."
if [ -d "$APP_DIR" ]; then
    echo "⚠️  App directory exists, removing..."
    rm -rf "$APP_DIR"
fi
git clone "$REPO_URL" "$APP_DIR"
cd "$APP_DIR"

# Build Docker image
echo "[4/5] Building Docker image..."
docker build -t "$CONTAINER_NAME" .

# Run container
echo "[5/5] Starting container on port $PORT..."
if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo "⚠️  Existing container found, removing..."
    docker stop "$CONTAINER_NAME" || true
    docker rm "$CONTAINER_NAME" || true
fi

docker run -d \
    -p "$PORT:80" \
    --name "$CONTAINER_NAME" \
    "$CONTAINER_NAME"

echo "=== Deployment Complete ==="
echo "Access the app at: http://$(curl -s ifconfig.me):$PORT"