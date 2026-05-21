#!/usr/bin/env bash
set -euo pipefail

PACKAGE_NAME="minimax-agent"
ARCH="x86_64"
DEB_ARCH="amd64"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${VERSION:-$(sed -nE 's/^VERSION="([^"]+)"/\1/p' "${SCRIPT_DIR}/build.sh" | head -n 1 | tr -d '\r')}"
BUILD_DIR="${SCRIPT_DIR}/linux-build"
APP_DIR="${BUILD_DIR}/opt/minimax-agent"
RPM_DIR="${SCRIPT_DIR}/rpm"
SPEC_FILE="${RPM_DIR}/${PACKAGE_NAME}.spec"
RPMBUILD_DIR="${SCRIPT_DIR}/.rpmbuild"
OUTPUT_DIR="${SCRIPT_DIR}/output"
SOURCE_DIR="${RPMBUILD_DIR}/SOURCES"
SPECS_DIR="${RPMBUILD_DIR}/SPECS"
CACHE_DIR="${SCRIPT_DIR}/.cache"
DEB_FILE="${CACHE_DIR}/${PACKAGE_NAME}_${VERSION}_${DEB_ARCH}.deb"
DEB_URL="${DEB_URL:-https://github.com/unn-Known1/minimax-agent-linux/releases/download/v${VERSION}/${PACKAGE_NAME}_${VERSION}_${DEB_ARCH}.deb}"
MIN_DEB_SIZE=$((50 * 1024 * 1024))

if [ -z "$VERSION" ]; then
    echo "Unable to determine package version from build.sh."
    exit 1
fi

file_size() {
    stat -c%s "$1" 2>/dev/null || stat -f%z "$1" 2>/dev/null
}

verify_deb() {
    local deb_file="$1"
    local size

    if [ ! -f "$deb_file" ]; then
        echo "Downloaded .deb was not found: $deb_file"
        return 1
    fi

    if [ ! -s "$deb_file" ]; then
        echo "Downloaded .deb is empty: $deb_file"
        return 1
    fi

    if ! size="$(file_size "$deb_file")"; then
        echo "Unable to determine downloaded .deb size: $deb_file"
        return 1
    fi

    if [ "$size" -lt "$MIN_DEB_SIZE" ]; then
        echo "Downloaded .deb is too small (${size} bytes): $deb_file"
        return 1
    fi

    if command -v dpkg-deb >/dev/null 2>&1; then
        if ! dpkg-deb --info "$deb_file" >/dev/null 2>&1; then
            echo "Downloaded file is not a valid .deb package: $deb_file"
            return 1
        fi
    elif command -v ar >/dev/null 2>&1; then
        if ! ar t "$deb_file" 2>/dev/null | grep -Eq '^data\.tar(\..+)?$'; then
            echo "Downloaded file does not look like a valid .deb package: $deb_file"
            return 1
        fi
    fi

    echo "  Verified .deb: $deb_file (${size} bytes)"
}

download_deb() {
    local tmp_file="${DEB_FILE}.tmp"

    mkdir -p "$CACHE_DIR"

    if [ -f "$DEB_FILE" ]; then
        echo "  Using cached .deb: $DEB_FILE"
        if verify_deb "$DEB_FILE"; then
            return 0
        fi

        echo "  Cached .deb failed verification; downloading a fresh copy."
        rm -f "$DEB_FILE"
    fi

    command -v curl >/dev/null 2>&1 || {
        echo "Missing tool: curl"
        echo "Install curl, then rerun this script."
        exit 1
    }

    echo "  Downloading .deb from GitHub releases..."
    echo "  URL: $DEB_URL"

    rm -f "$tmp_file"
    if ! curl -fL --retry 12 --retry-delay 10 --retry-all-errors -o "$tmp_file" "$DEB_URL"; then
        rm -f "$tmp_file"
        echo "Failed to download .deb package."
        exit 1
    fi

    mv "$tmp_file" "$DEB_FILE"
    verify_deb "$DEB_FILE" || {
        rm -f "$DEB_FILE"
        echo "Downloaded .deb failed verification."
        exit 1
    }
}

extract_deb_payload() {
    local tmpdir
    local data_archive=""
    local status=0

    tmpdir="$(mktemp -d)"
    mkdir -p "${tmpdir}/root"

    if command -v dpkg-deb >/dev/null 2>&1; then
        echo "  Extracting .deb with dpkg-deb..."
        dpkg-deb -x "$DEB_FILE" "${tmpdir}/root" || status=$?
    else
        echo "  dpkg-deb not found; extracting .deb with ar + tar..."

        command -v ar >/dev/null 2>&1 || {
            rm -rf "$tmpdir"
            echo "Missing tool: ar"
            echo "Install dpkg-deb, or install ar and tar for fallback extraction."
            return 1
        }

        command -v tar >/dev/null 2>&1 || {
            rm -rf "$tmpdir"
            echo "Missing tool: tar"
            echo "Install dpkg-deb, or install ar and tar for fallback extraction."
            return 1
        }

        mkdir -p "${tmpdir}/ar"
        (
            cd "${tmpdir}/ar"
            ar x "$DEB_FILE"
        ) || status=$?

        if [ "$status" -eq 0 ]; then
            for archive in "${tmpdir}/ar"/data.tar "${tmpdir}/ar"/data.tar.*; do
                if [ -f "$archive" ]; then
                    data_archive="$archive"
                    break
                fi
            done

            if [ -z "$data_archive" ]; then
                status=1
                echo "No data.tar archive found inside .deb."
            else
                tar -xf "$data_archive" -C "${tmpdir}/root" || status=$?
            fi
        fi
    fi

    if [ "$status" -ne 0 ]; then
        rm -rf "$tmpdir"
        echo "Failed to extract .deb package."
        return "$status"
    fi

    if [ ! -d "${tmpdir}/root/opt/minimax-agent" ]; then
        rm -rf "$tmpdir"
        echo "Extracted .deb does not contain /opt/minimax-agent."
        return 1
    fi

    mkdir -p "${BUILD_DIR}/opt"
    cp -a "${tmpdir}/root/opt/minimax-agent" "${BUILD_DIR}/opt/"

    rm -rf "$tmpdir"
}

ensure_app_payload() {
    if [ -d "$APP_DIR" ]; then
        echo "  Found package payload: linux-build/opt/minimax-agent"
        return 0
    fi

    echo "  Missing package payload: linux-build/opt/minimax-agent"
    echo "  Bootstrapping Electron/runtime assets from the release .deb."

    download_deb
    extract_deb_payload

    if [ ! -d "$APP_DIR" ]; then
        echo "Failed to stage package payload: linux-build/opt/minimax-agent"
        exit 1
    fi

    echo "  Package payload staged successfully."
}

normalize_text_payload() {
    local file
    local text_files=(
        "${BUILD_DIR}/usr/bin/minimax-agent"
        "${BUILD_DIR}/usr/share/applications/minimax-agent.desktop"
        "${APP_DIR}/LICENSES.chromium.html"
        "${APP_DIR}/resources/app-update.yml"
        "${APP_DIR}/version"
    )

    for file in "${text_files[@]}"; do
        if [ -f "$file" ] && LC_ALL=C grep -q $'\r' "$file"; then
            sed -i 's/\r$//' "$file"
            echo "  Normalized line endings: ${file#"${SCRIPT_DIR}/"}"
        fi
    done
}

echo "=========================================="
echo "  MiniMax Agent RPM Build Script"
echo "=========================================="
echo ""

if [ ! -f "$SPEC_FILE" ]; then
    echo "Missing RPM spec: $SPEC_FILE"
    exit 1
fi

if [ ! -d "${BUILD_DIR}/usr" ]; then
    echo "Missing package payload: linux-build/usr"
    exit 1
fi

echo "[1/7] Ensuring application payload..."
ensure_app_payload
echo ""

echo "[2/7] Normalizing text payload..."
normalize_text_payload
echo ""

echo "[3/7] Checking build dependencies..."
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

echo "[4/7] Preparing rpmbuild tree..."
rm -rf "$RPMBUILD_DIR"
mkdir -p "$SOURCE_DIR" "$SPECS_DIR" "${RPMBUILD_DIR}/BUILD" "${RPMBUILD_DIR}/BUILDROOT" "${RPMBUILD_DIR}/RPMS" "${RPMBUILD_DIR}/SRPMS" "$OUTPUT_DIR"

echo "[5/7] Creating source archive..."
tar \
    --exclude=".git" \
    --exclude=".cache" \
    --exclude=".rpmbuild" \
    --exclude="output" \
    --exclude="*.deb" \
    --exclude="*.rpm" \
    -czf "${SOURCE_DIR}/${PACKAGE_NAME}-${VERSION}.tar.gz" \
    --transform "s,^\.,${PACKAGE_NAME}-${VERSION}," \
    -C "$SCRIPT_DIR" .

cp "$SPEC_FILE" "$SPECS_DIR/"

echo "[6/7] Building RPM..."
rpmbuild \
    --define "_topdir ${RPMBUILD_DIR}" \
    --define "app_version ${VERSION}" \
    -bb "${SPECS_DIR}/${PACKAGE_NAME}.spec"

echo "[7/7] Collecting output..."
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
