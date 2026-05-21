#!/bin/bash
# MiniMax Agent Linux Build Script
# This script builds the .deb package from the source files

set -e

VERSION="3.0.13"
ARCH="amd64"

# Use absolute paths for safety
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/linux-build"
OUTPUT_DIR="${SCRIPT_DIR}/output"
PACKAGE_NAME="minimax-agent_${VERSION}_${ARCH}.deb"

echo "=========================================="
echo "  MiniMax Agent Linux Build Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Warning: Not running as root. Some operations may fail."
    echo "Consider running with: sudo $0"
    echo ""
fi

# Safety check: Verify we're in the expected directory
if [ ! -f "${SCRIPT_DIR}/package.json" ] && [ ! -d "${SCRIPT_DIR}/linux-build" ]; then
    echo "Error: This script must be run from the project root directory."
    echo "Expected files: package.json or linux-build directory"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
chmod 755 "$OUTPUT_DIR"

# Check for required tools
echo "[1/4] Checking build dependencies..."
MISSING_TOOLS=()
command -v dpkg-deb >/dev/null 2>&1 || MISSING_TOOLS+=("dpkg-dev")
command -v fakeroot >/dev/null 2>&1 || MISSING_TOOLS+=("fakeroot")

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "Missing tools: ${MISSING_TOOLS[*]}"
    echo "Install them with: sudo apt install ${MISSING_TOOLS[*]}"
    exit 1
fi

echo "  All dependencies satisfied."

# Clean previous builds with safety checks
echo ""
echo "[2/4] Cleaning previous builds..."
if [ -f "$OUTPUT_DIR/$PACKAGE_NAME" ]; then
    # Verify OUTPUT_DIR is within SCRIPT_DIR before deletion
    case "$OUTPUT_DIR" in
        "${SCRIPT_DIR}"*)
            rm -f "$OUTPUT_DIR/$PACKAGE_NAME"
            ;;
        *)
            echo "Error: Output directory is outside project directory. Aborting for safety."
            exit 1
            ;;
    esac
fi

# Clean build artifacts with safety check
if [ -d "$BUILD_DIR/DEBIAN" ]; then
    case "$BUILD_DIR" in
        "${SCRIPT_DIR}"*)
            rm -f "$BUILD_DIR/DEBIAN"/*.deb 2>/dev/null || true
            ;;
        *)
            echo "Error: Build directory is outside project directory. Aborting for safety."
            exit 1
            ;;
    esac
fi

# Ensure maintainer scripts are executable (required by dpkg)
if [ -d "$BUILD_DIR/DEBIAN" ]; then
    chmod 755 "$BUILD_DIR/DEBIAN"/postinst "$BUILD_DIR/DEBIAN"/prerm 2>/dev/null || true
fi

# Ensure launcher is executable
if [ -f "$BUILD_DIR/usr/bin/minimax-agent" ]; then
    chmod 755 "$BUILD_DIR/usr/bin/minimax-agent"
fi

# Build the package
echo ""
echo "[3/4] Building package..."
dpkg-deb --build "$BUILD_DIR" "$OUTPUT_DIR/$PACKAGE_NAME"

# Verify the package
echo ""
echo "[4/4] Verifying package..."
if [ -f "$OUTPUT_DIR/$PACKAGE_NAME" ]; then
    echo "  Package created successfully!"
    ls -lh "$OUTPUT_DIR/$PACKAGE_NAME"
    echo ""
    echo "  Install with: sudo dpkg -i $OUTPUT_DIR/$PACKAGE_NAME"
else
    echo "  Error: Package creation failed!"
    exit 1
fi

echo ""
echo "=========================================="
echo "  Build Complete!"
echo "=========================================="
