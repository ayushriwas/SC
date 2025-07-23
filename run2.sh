#!/bin/bash
set -e

echo "🚀 Updating package lists and installing build dependencies..."
sudo apt update
sudo apt install -y \
  cmake build-essential pkg-config \
  libglib2.0-dev libgnutls28-dev libgnutls-openssl27 \
  libmicrohttpd-dev libxml2-dev libpcap-dev libssh-dev \
  libksba8 libksba-dev libgpgme-dev libgnutls28-dev \
  libjson-glib-dev libhiredis-dev libsnmp-dev \
  uuid-dev redis-server python3-paramiko python3-lxml \
  python3-defusedxml python3-pip python3-psutil python3-setuptools \
  python3-cffi python3-greenlet python3-openssl \
  xml-twig-tools git

echo "📁 Creating source directory at ~/gvm-source..."
mkdir -p ~/gvm-source
cd ~/gvm-source

# Function to clone, checkout tag, build and install
build_component() {
  local repo_url=$1
  local folder_name=$2
  local tag=$3

  echo "🔁 Cloning $folder_name repository..."
  if [ -d "$folder_name" ]; then
    echo "⚠️ Directory $folder_name exists. Removing it first..."
    rm -rf "$folder_name"
  fi
  git clone "$repo_url"
  cd "$folder_name"
  git fetch --tags
  echo "🔍 Checking out tag $tag..."
  git checkout "tags/$tag" -b build-$tag
  mkdir -p build && cd build
  echo "🔧 Building $folder_name..."
  cmake ..
  make -j$(nproc)
  echo "📥 Installing $folder_name..."
  sudo make install
  cd ../../
}

# Build gvmd
build_component https://github.com/greenbone/gvmd.git gvmd v24.0.0

# Build gsad
build_component https://github.com/greenbone/gsad.git gsad v24.0.0

# Build ospd-openvas (the scanner daemon wrapper)
build_component https://github.com/greenbone/ospd-openvas.git ospd-openvas v24.0.0

echo "✅ All components built and installed successfully."

echo "🔄 Setting up Redis for GVM..."
sudo systemctl enable redis-server
sudo systemctl restart redis-server

echo "🔄 Restarting GVM services..."
sudo systemctl daemon-reload
sudo systemctl restart gvmd || true
sudo systemctl restart ospd-openvas || true
sudo systemctl restart gsad || true

echo "🌐 Installation complete! Access the web UI at: https://127.0.0.1:9392"
