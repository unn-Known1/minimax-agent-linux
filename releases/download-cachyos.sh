#!/bin/bash
# download-cachyos.sh — One-shot installer for Cachy OS / Arch users
#
# Detects the host distribution, picks the right package from the
# matching GitHub release asset, verifies it, and installs via pacman.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/unn-Known1/minimax-agent-linux/main/releases/download-cachyos.sh | sudo bash
#
# Or download and run:
#   sudo ./download-cachyos.sh
#
# Options:
#   --version=X.Y.Z   Install a specific version (default: latest)
#   --no-install      Download + verify only
#   --quiet           Less output

set -euo pipefail

# ────────────────────────── option parsing ──────────────────────────
REQUESTED_VERSION=""
NO_INSTALL=0
QUIET=0
for arg in "$@"; do
    case "${arg}" in
        --version=*) REQUESTED_VERSION="${arg#--version=}" ;;
        --no-install) NO_INSTALL=1 ;;
        --quiet)      QUIET=1 ;;
        -h|--help)
            sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown option: ${arg}" >&2
            exit 2
            ;;
    esac
done

REPO="unn-Known1/minimax-agent-linux"
GITHUB_API="https://api.github.com/repos/${REPO}"
GITHUB_RELEASES="https://github.com/${REPO}/releases"

log()  { [ "${QUIET}" -eq 0 ] && echo "==> $*"; }
warn() { echo "WARNING: $*" >&2; }
die()  { echo "ERROR: $*" >&2; exit 1; }

# ────────────────────────── host detection ──────────────────────────
detect_distro() {
    if [ -f /etc/cachyos-release ]; then
        echo "cachyos"
        return
    fi
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "${ID:-}" in
            cachyos)            echo "cachyos" ;;
            arch)               echo "arch" ;;
            manjaro)            echo "manjaro" ;;
            endeavour*)         echo "endeavouros" ;;
            garuda)             echo "garuda" ;;
            artix)              echo "arch" ;;  # artix is arch-derived
            *)                  echo "${ID:-unknown}" ;;
        esac
    else
        echo "unknown"
    fi
}

DISTRO="$(detect_distro)"
case "${DISTRO}" in
    cachyos|arch|manjaro|endeavouros|garuda)
        log "Detected: ${DISTRO} (Arch-based — proceeding with pacman)" ;;
    *)
        warn "Host distro is '${DISTRO}', which is not Arch-based."
        warn "This script installs a pacman package and is not appropriate here."
        warn "On Debian/Ubuntu, use releases/download.sh instead."
        exit 1
        ;;
esac

if ! command -v pacman >/dev/null 2>&1; then
    die "pacman not found; this is not an Arch-based system."
fi

# ────────────────────────── version detection ──────────────────────────
if [ -z "${REQUESTED_VERSION}" ]; then
    log "Looking up latest release..."
    if command -v curl >/dev/null 2>&1; then
        REQUESTED_VERSION="$(curl -fsSL "${GITHUB_API}/releases/latest" 2>/dev/null \
            | grep -oE '"tag_name":\s*"v?[^"]+"' \
            | head -1 \
            | sed -E 's/.*"v?([^"]+)".*/\1/')"
    fi
fi

if [ -z "${REQUESTED_VERSION}" ]; then
    die "Could not determine latest version. Pass --version=X.Y.Z explicitly."
fi

# Strip leading 'v' if present
REQUESTED_VERSION="${REQUESTED_VERSION#v}"

PKG_FILE="minimax-agent-${REQUESTED_VERSION}-1-x86_64.pkg.tar.zst"
DOWNLOAD_URL="${GITHUB_RELEASES}/download/v${REQUESTED_VERSION}/${PKG_FILE}"
CHECKSUM_URL="${GITHUB_RELEASES}/download/v${REQUESTED_VERSION}/SHA256SUMS"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/minimax-agent/installer"
mkdir -p "${CACHE_DIR}"
DEST="${CACHE_DIR}/${PKG_FILE}"

log "Version:    ${REQUESTED_VERSION}"
log "Distro:     ${DISTRO}"
log "Package:    ${PKG_FILE}"
log "Source:     ${DOWNLOAD_URL}"

# ────────────────────────── download ──────────────────────────
if [ -f "${DEST}" ]; then
    log "Using cached ${DEST}"
else
    log "Downloading..."
    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 --retry-delay 2 -o "${DEST}.tmp" "${DOWNLOAD_URL}"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "${DEST}.tmp" "${DOWNLOAD_URL}"
    else
        die "Neither curl nor wget found. Install one and retry."
    fi
    mv "${DEST}.tmp" "${DEST}"
    log "Downloaded $(du -h "${DEST}" | cut -f1)."
fi

# ────────────────────────── verify ──────────────────────────
if command -v sha256sum >/dev/null 2>&1; then
    if [ "${QUIET}" -eq 0 ]; then
        log "Verifying SHA256..."
    fi
    CHECKSUM_FILE="${CACHE_DIR}/SHA256SUMS-${REQUESTED_VERSION}"
    if [ ! -f "${CHECKSUM_FILE}" ]; then
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL -o "${CHECKSUM_FILE}.tmp" "${CHECKSUM_URL}" 2>/dev/null || rm -f "${CHECKSUM_FILE}.tmp"
            [ -f "${CHECKSUM_FILE}.tmp" ] && mv "${CHECKSUM_FILE}.tmp" "${CHECKSUM_FILE}" || true
        fi
    fi
    if [ -f "${CHECKSUM_FILE}" ]; then
        EXPECTED="$(grep "  ${PKG_FILE}\$" "${CHECKSUM_FILE}" 2>/dev/null | awk '{print $1}')"
        if [ -n "${EXPECTED}" ]; then
            ACTUAL="$(sha256sum "${DEST}" | awk '{print $1}')"
            if [ "${EXPECTED}" != "${ACTUAL}" ]; then
                die "Checksum mismatch — refusing to install. Delete ${DEST} and retry."
            fi
            log "SHA256 verified."
        else
            warn "Package not present in SHA256SUMS; skipping integrity check."
        fi
    else
        warn "SHA256SUMS not published for this release; skipping integrity check."
    fi
fi

# ────────────────────────── install ──────────────────────────
if [ "${NO_INSTALL}" -eq 1 ]; then
    log "Download-only mode. Package at: ${DEST}"
    exit 0
fi

# pacman needs root
if [ "$(id -u)" -ne 0 ]; then
    die "Install requires root. Re-run with: sudo $0"
fi

# Refresh dependencies on Cachy OS / Arch before installing
log "Resolving dependencies..."
pacman -Sy --noconfirm --needed >/dev/null 2>&1 || warn "pacman -Sy had warnings; continuing."

log "Installing with pacman -U..."
pacman -U --noconfirm "${DEST}"

log "Done."
log ""
log "Launch with:   minimax-agent"
log "Service logs:  journalctl --user -u mavis.service"
log "Troubleshooting: see INSTALL.md (Cachy OS section)."
