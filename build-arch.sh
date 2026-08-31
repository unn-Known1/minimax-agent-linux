#!/bin/bash
# build-arch.sh — DEPRECATED. Kept as a fallback only.
#
# This script used to build an Arch Linux package by converting the
# .deb with `debtap`. That approach is lossy (wrong dependency names,
# no install hook, no AUR path, no Cachy OS optimization) and is no
# longer recommended.
#
# Please use the new PKGBUILD-based flow instead:
#
#   ./build-cachyos.sh              # native on a Cachy OS / Arch host
#   ./build-cachyos.sh --docker     # cross-build in a Docker container
#   ./build-cachyos.sh --v3         # force x86-64-v3 CFLAGS
#
# See cachyos/PKGBUILD, cachyos/minimax-agent.install, AGENTS.md,
# and INSTALL.md for the full documentation.
#
# If you really must use this script, it will forward to the new one.
# Remove this file once you are confident everyone has migrated.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==========================================="
echo "  WARNING: build-arch.sh is DEPRECATED"
echo "==========================================="
echo ""
echo "  This script used 'debtap' to convert the .deb to an Arch"
echo "  package. That produced a low-quality, non-AUR, non-Cachy-OS"
echo "  artifact."
echo ""
echo "  Please use build-cachyos.sh instead:"
echo "    ./build-cachyos.sh"
echo ""
echo "  Forwarding to build-cachyos.sh in 3 seconds..."
echo ""
sleep 3

if [ -x "${SCRIPT_DIR}/build-cachyos.sh" ]; then
    exec "${SCRIPT_DIR}/build-cachyos.sh" "$@"
else
    echo "ERROR: build-cachyos.sh not found." >&2
    echo "       Pull the latest from main, or grab cachyos/PKGBUILD" >&2
    echo "       and run makepkg from there directly." >&2
    exit 1
fi
