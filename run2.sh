#!/bin/bash

set -e

echo "📦 Removing existing (incompatible) gsad..."
sudo rm -f /usr/local/sbin/gsad /usr/sbin/gsad

echo "📁 Creating source directory..."
mkdir -p ~/gvm-source
cd ~/gvm-source

echo "🔁 Cloning gsad repository..."
git clone https://github.com/greenbone/gsad.git
cd gsad

echo "🔍 Checking out latest tag for GVM 24.0..."
git fetch --tags
# Use a specific tag that aligns with GVM 24.0 (e.g., v24.0.0 or closest stable)
LATEST_TAG=$(git tag -l | grep '^v24\.0' | sort -V | tail -n 1)

if [ -z "$LATEST_TAG" ]; then
    echo "❌ Could not find a suitable tag for GVM 24.0"
    exit 1
fi

echo "✅ Found tag: $LATEST_TAG"
git checkout tags/$LATEST_TAG -b build-24.0

echo "🔧 Building gsad from source..."
mkdir -p build
cd build
cmake ..
make -j$(nproc)

echo "📥 Installing gsad..."
sudo make install

echo "✅ gsad $LATEST_TAG installed successfully."

echo "🔄 Restarting GVM services..."
sudo systemctl restart gvmd
sudo systemctl restart ospd-openvas
sudo systemctl restart gsad

sleep 3

echo "🔎 Checking gsad status..."
sudo systemctl status gsad --no-pager

echo "🌐 If no errors above, access the Web UI at: https://127.0.0.1:9392"
