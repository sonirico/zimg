#!/bin/bash

# zimg installer script
# Usage: curl -sSL https://raw.githubusercontent.com/sonirico/zimg/main/install.sh | bash

set -e

# Detect platform
OS="$(uname -s)"
ARCH="$(uname -m)"

case $OS in
    Linux*)
        PLATFORM="linux"
        ;;
    Darwin*)
        PLATFORM="darwin"
        ;;
    CYGWIN*|MINGW*|MSYS*)
        PLATFORM="windows"
        ;;
    *)
        echo "Unsupported operating system: $OS"
        exit 1
        ;;
esac

case $ARCH in
    x86_64|amd64)
        ARCH="x86_64"
        ;;
    arm64|aarch64)
        ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

BINARY_NAME="zimg-${PLATFORM}-${ARCH}"
if [ "$PLATFORM" = "windows" ]; then
    BINARY_NAME="${BINARY_NAME}.exe"
fi

# Get latest release
LATEST_RELEASE=$(curl -s https://api.github.com/repos/sonirico/zimg/releases/latest | grep -oP '"tag_name": "\K[^"]+')

if [ -z "$LATEST_RELEASE" ]; then
    echo "Failed to get latest release information"
    exit 1
fi

echo "Installing zimg $LATEST_RELEASE for $PLATFORM-$ARCH..."

# Download binary
DOWNLOAD_URL="https://github.com/sonirico/zimg/releases/download/${LATEST_RELEASE}/${BINARY_NAME}"
INSTALL_DIR="${HOME}/.local/bin"

mkdir -p "$INSTALL_DIR"

echo "Downloading from $DOWNLOAD_URL..."
curl -L "$DOWNLOAD_URL" -o "${INSTALL_DIR}/zimg"
chmod +x "${INSTALL_DIR}/zimg"

echo "zimg installed successfully to ${INSTALL_DIR}/zimg"
echo ""
echo "Make sure ${INSTALL_DIR} is in your PATH:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""
echo "Test the installation:"
echo "  zimg --help"
