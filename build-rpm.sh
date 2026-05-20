#!/usr/bin/env bash
set -euo pipefail

VERSION="3.0.13"
PACKAGE_NAME="minimax-agent"
ARCH="x86_64"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RPM_DIR="${SCRIPT_DIR}/rpm"
SPEC_FILE="${RPM_DIR}/${PACKAGE_NAME}.spec"
RPMBUILD_DIR="${SCRIPT_DIR}/.rpmbuild"
OUTPUT_DIR="${SCRIPT_DIR}/output"
SOURCE_DIR="${RPMBUILD_DIR}/SOURCES"
SPECS_DIR="${RPMBUILD_DIR}/SPECS"

echo "=========================================="
echo "  MiniMax Agent RPM Build Script"
echo "=========================================="
echo ""

if [ ! -f "$SPEC_FILE" ]; then
    echo "Missing RPM spec: $SPEC_FILE"
    exit 1
fi

if [ ! -d "${SCRIPT_DIR}/linux-build/usr" ]; then
    echo "Missing package payload: linux-build/usr"
    exit 1
fi

if [ ! -d "${SCRIPT_DIR}/linux-build/opt/minimax-agent" ]; then
    echo "Missing package payload: linux-build/opt/minimax-agent"
    echo "Stage Electron/runtime assets before building the RPM."
    exit 1
fi

echo "[1/5] Checking build dependencies..."
missing_tools=()
command -v rpmbuild >/dev/null 2>&1 || missing_tools+=("rpm-build")
command -v tar >/dev/null 2>&1 || missing_tools+=("tar")
command -v desktop-file-validate >/dev/null 2>&1 || missing_tools+=("desktop-file-utils")

if [ "${#missing_tools[@]}" -ne 0 ]; then
    echo "Missing tools: ${missing_tools[*]}"
    echo "Fedora/RHEL: sudo dnf install rpm-build rpmdevtools desktop-file-utils tar gzip"
    echo "openSUSE: sudo zypper install rpm-build desktop-file-utils tar gzip"
    exit 1
fi

echo "  All dependencies satisfied."
echo ""

echo "[2/5] Preparing rpmbuild tree..."
rm -rf "$RPMBUILD_DIR"
mkdir -p "$SOURCE_DIR" "$SPECS_DIR" "${RPMBUILD_DIR}/BUILD" "${RPMBUILD_DIR}/BUILDROOT" "${RPMBUILD_DIR}/RPMS" "${RPMBUILD_DIR}/SRPMS" "$OUTPUT_DIR"

echo "[3/5] Creating source archive..."
tar \
    --exclude=".git" \
    --exclude=".rpmbuild" \
    --exclude="output" \
    --exclude="*.deb" \
    --exclude="*.rpm" \
    -czf "${SOURCE_DIR}/${PACKAGE_NAME}-${VERSION}.tar.gz" \
    --transform "s,^\.,${PACKAGE_NAME}-${VERSION}," \
    -C "$SCRIPT_DIR" .

cp "$SPEC_FILE" "$SPECS_DIR/"

echo "[4/5] Building RPM..."
rpmbuild \
    --define "_topdir ${RPMBUILD_DIR}" \
    -bb "${SPECS_DIR}/${PACKAGE_NAME}.spec"

echo "[5/5] Collecting output..."
rpm_path="$(find "${RPMBUILD_DIR}/RPMS/${ARCH}" -type f -name "${PACKAGE_NAME}-${VERSION}-*.${ARCH}.rpm" | head -n 1)"

if [ -z "$rpm_path" ] || [ ! -f "$rpm_path" ]; then
    echo "RPM build completed but output RPM was not found."
    exit 1
fi

cp "$rpm_path" "$OUTPUT_DIR/"

echo ""
echo "RPM created successfully:"
ls -lh "${OUTPUT_DIR}/$(basename "$rpm_path")"
echo ""
echo "Inspect with:"
echo "  rpm -qpi ${OUTPUT_DIR}/$(basename "$rpm_path")"
echo "  rpm -qpl ${OUTPUT_DIR}/$(basename "$rpm_path")"
echo ""
echo "Install with:"
echo "  sudo dnf install ${OUTPUT_DIR}/$(basename "$rpm_path")"
echo "  sudo zypper install ${OUTPUT_DIR}/$(basename "$rpm_path")"
