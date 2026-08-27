#!/bin/bash
# Download and install MiniMax Agent for Linux
# Usage: sudo ./download.sh

set -e

VERSION="3.0.68"
DEB_FILE="minimax-agent_${VERSION}_amd64.deb"
GITHUB_URL="https://github.com/unn-Known1/minimax-agent-linux/releases/download/v3.0.68/minimax-agent_3.0.68_amd64.deb"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (sudo $0)"
    exit 1
fi

# Verify checksum function
verify_checksum() {
    local file="$1"
    local expected_hash="$2"
    local algorithm="${3:-sha256}"

    if [ ! -f "$file" ]; then
        return 1
    fi

    local actual_hash
    case "$algorithm" in
        sha256)
            actual_hash=$(sha256sum "$file" | awk '{print $1}')
            ;;
        sha512)
            actual_hash=$(sha512sum "$file" | awk '{print $1}')
            ;;
        md5)
            actual_hash=$(md5sum "$file" | awk '{print $1}')
            ;;
        *)
            echo "Unsupported hash algorithm: $algorithm"
            return 1
            ;;
    esac

    if [ "$actual_hash" = "$expected_hash" ]; then
        return 0
    else
        echo "Checksum verification failed!"
        echo "Expected: $expected_hash"
        echo "Actual:   $actual_hash"
        return 1
    fi
}

# Download with retry
download_with_retry() {
    local url="$1"
    local output="$2"
    local max_retries=3
    local retry=0

    while [ $retry -lt $max_retries ]; do
        echo "Downloading MiniMax Agent $VERSION (attempt $((retry + 1))/$max_retries)..."
        if curl -fsSL --retry 3 --retry-delay 2 -o "$output" "$url"; then
            return 0
        fi
        echo "Download failed. Retrying..."
        rm -f "$output"
        retry=$((retry + 1))
        sleep 2
    done

    echo "Download failed after $max_retries attempts"
    return 1
}

# Download the .deb file
if [ ! -f "$DEB_FILE" ]; then
    if ! download_with_retry "$GITHUB_URL" "$DEB_FILE"; then
        echo "Error: Failed to download MiniMax Agent"
        exit 1
    fi
else
    echo "Using cached file: $DEB_FILE"
fi

# Verify the downloaded file
echo "Verifying download..."
if [ -f "$DEB_FILE" ]; then
    # Check file size is reasonable (should be around 100-200MB)
    FILE_SIZE=$(stat -f%z "$DEB_FILE" 2>/dev/null || stat -c%s "$DEB_FILE" 2>/dev/null)
    MIN_SIZE=$((50 * 1024 * 1024))  # 50MB minimum
    MAX_SIZE=$((500 * 1024 * 1024))  # 500MB maximum

    if [ "$FILE_SIZE" -lt "$MIN_SIZE" ]; then
        echo "Error: Downloaded file is too small ($FILE_SIZE bytes). It may be corrupted."
        rm -f "$DEB_FILE"
        exit 1
    fi

    if [ "$FILE_SIZE" -gt "$MAX_SIZE" ]; then
        echo "Error: Downloaded file is too large ($FILE_SIZE bytes). It may be corrupted."
        rm -f "$DEB_FILE"
        exit 1
    fi

    echo "File size verified: $(echo "scale=2; $FILE_SIZE / 1024 / 1024" | bc) MB"
else
    echo "Error: Downloaded file not found"
    exit 1
fi

# Install the package
echo "Installing MiniMax Agent..."
if dpkg -i "$DEB_FILE"; then
    echo "Package installed successfully!"
else
    echo "Package installation failed. Attempting to fix dependencies..."
    if apt --fix-broken install -y; then
        echo "Dependencies fixed and package installed!"
    else
        echo "Error: Failed to install package and fix dependencies"
        exit 1
    fi
fi

echo ""
echo "Installation complete!"
echo "Launch with: minimax-agent"