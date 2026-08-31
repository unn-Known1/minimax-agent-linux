#!/bin/bash
# build-cachyos.sh — Build Arch / Cachy OS package from the project tree
#
# This is the proper replacement for the old debtap-based build-arch.sh.
# It uses a real PKGBUILD + makepkg, which gives us:
#   - Clean AUR-compatible output
#   - Cachy OS detection + x86-64-v3 CFLAGS when applicable
#   - The same install-time behavior as the .deb
#
# It can run on:
#   1. A Cachy OS / Arch host (recommended) — produces the real .pkg.tar.zst
#   2. Any Linux host with Docker + an Arch/Cachy OS base image
#   3. macOS / WSL — produces a tarball that can be copied to a Cachy
#      OS host and rebuilt there with `./build-cachyos.sh --rebuild`
#
# Usage:
#   ./build-cachyos.sh                # build on the current host
#   ./build-cachyos.sh --docker       # build inside an Arch container
#   ./build-cachyos.sh --rebuild      # rebuild from a prepared tarball
#   ./build-cachyos.sh --v3           # force x86-64-v3 CFLAGS
#   ./build-cachyos.sh --clean        # nuke PKGBUILD build dirs
#
# Output goes to releases/minimax-agent-<version>-<rel>-x86_64.pkg.tar.zst

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

PKG_DIR="${SCRIPT_DIR}/cachyos"
OUTPUT_DIR="${SCRIPT_DIR}/releases"

# Extract version from PKGBUILD so this script can't drift from it.
PKGVER=$(grep -E '^pkgver=' "${PKG_DIR}/PKGBUILD" | head -1 | cut -d= -f2 | tr -d '"'\'' ')
PKGREL=$(grep -E '^pkgrel=' "${PKG_DIR}/PKGBUILD" | head -1 | cut -d= -f2 | tr -d '"'\'' ')

if [ -z "${PKGVER}" ] || [ -z "${PKGREL}" ]; then
    echo "ERROR: could not parse pkgver/pkgrel from ${PKG_DIR}/PKGBUILD" >&2
    exit 1
fi

PKG_NAME="minimax-agent-${PKGVER}-${PKGREL}-x86_64.pkg.tar.zst"

# ────────────────────────── option parsing ──────────────────────────
USE_DOCKER=0
REBUILD_ONLY=0
FORCE_V3=0
CLEAN=0
for arg in "$@"; do
    case "${arg}" in
        --docker)   USE_DOCKER=1 ;;
        --rebuild)  REBUILD_ONLY=1 ;;
        --v3)       FORCE_V3=1 ;;
        --clean)    CLEAN=1 ;;
        -h|--help)
            sed -n '2,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown option: ${arg}" >&2
            exit 2
            ;;
    esac
done

# ────────────────────────── helpers ──────────────────────────
log()  { echo "==> $*"; }
warn() { echo "WARNING: $*" >&2; }
die()  { echo "ERROR: $*" >&2; exit 1; }

is_cachyos() {
    if [ -f /etc/cachyos-release ]; then
        return 0
    fi
    if [ -f /etc/os-release ] && grep -qi 'cachyos' /etc/os-release 2>/dev/null; then
        return 0
    fi
    return 1
}

is_arch() {
    if [ -f /etc/arch-release ]; then
        return 0
    fi
    if [ -f /etc/os-release ] && grep -qi '^ID=arch' /etc/os-release 2>/dev/null; then
        return 0
    fi
    return 1
}

# ────────────────────────── --clean ──────────────────────────
if [ "${CLEAN}" -eq 1 ]; then
    log "Cleaning PKGBUILD build dirs..."
    rm -rf "${SCRIPT_DIR}/pkg" "${SCRIPT_DIR}/src" "${SCRIPT_DIR}"/minimax-agent-linux-*.tar.gz
    log "Done."
    exit 0
fi

mkdir -p "${OUTPUT_DIR}"

# ────────────────────────── prerequisites ──────────────────────────
log "Checking prerequisites..."

if [ "${USE_DOCKER}" -eq 1 ]; then
    command -v docker >/dev/null 2>&1 || die "docker not found; --docker requires Docker"
    log "Using Docker (archlinux:latest base)."
fi

if [ "${REBUILD_ONLY}" -eq 0 ] && [ "${USE_DOCKER}" -eq 0 ]; then
    if [ "${USE_DOCKER}" -eq 0 ]; then
        if ! is_arch && ! is_cachyos; then
            warn "This host is not Arch or Cachy OS."
            warn "Use --docker, or build on an Arch-based host."
            warn "Continuing with --docker fallback."
            USE_DOCKER=1
        fi
    fi
fi

# ────────────────────────── source preparation ──────────────────────────
# We need a tarball of the project root that the PKGBUILD can extract
# into $srcdir/minimax-agent-linux-${PKGVER}/. The PKGBUILD's
# `source=(... .tar.gz::archive/refs/tags/v${PKGVER}.tar.gz)` is
# what makepkg fetches. We override that by:
#   - pre-placing the tarball in $SRCDEST, OR
#   - building the PKGBUILD with the local source (preferred here)
#
# Approach: build a tarball from the working tree, then invoke
# makepkg with --source / --nocheck / etc. We honor any pre-existing
# tag tarball in the cache so CI doesn't rebuild it.
TARBALL="${SCRIPT_DIR}/minimax-agent-linux-${PKGVER}.tar.gz"
NEEDS_TARBALL=1
if [ -f "${TARBALL}" ]; then
    log "Found existing ${TARBALL}; reusing."
    NEEDS_TARBALL=0
fi

if [ "${NEEDS_TARBALL}" -eq 1 ]; then
    log "Building source tarball from working tree..."
    TMPDIR_SRC="$(mktemp -d)"
    trap 'rm -rf "${TMPDIR_SRC}"' EXIT
    SRC_STAGE="${TMPDIR_SRC}/minimax-agent-linux-${PKGVER}"
    mkdir -p "${SRC_STAGE}"
    # Copy everything except heavy / generated dirs
    rsync -a --exclude='.git' \
              --exclude='output' \
              --exclude='releases/*.deb' \
              --exclude='releases/*.pkg.tar*' \
              --exclude='cachyos/pkg' \
              --exclude='cachyos/src' \
              --exclude='*.tar.gz' \
              "${SCRIPT_DIR}/" "${SRC_STAGE}/"
    # Move cachyos/ into the right place inside the staged tree
    if [ -d "${SCRIPT_DIR}/cachyos" ]; then
        mkdir -p "${SRC_STAGE}/cachyos"
        cp -a "${SCRIPT_DIR}/cachyos/." "${SRC_STAGE}/cachyos/"
    fi
    (cd "${TMPDIR_SRC}" && tar -czf "${TARBALL}" "minimax-agent-linux-${PKGVER}")
    log "Tarball: ${TARBALL} ($(du -h "${TARBALL}" | cut -f1))"
fi

# ────────────────────────── build via makepkg ──────────────────────────
run_makepkg() {
    local srcdest="$1"
    local pkgdest="$2"
    local extra_flags=( "$@" )
    local cmd=(makepkg
        --syncdeps
        --noconfirm
        --nocheck
        --clean
        --skippgpcheck
        --skipinteg
        --holdver
        -D
        "PKGDEST=${pkgdest}"
        "SRCDEST=${srcdest}"
    )
    cmd+=( "${extra_flags[@]}" )

    if [ "${FORCE_V3}" -eq 1 ]; then
        CFLAGS="-march=x86-64-v3 -O2 -pipe ${CFLAGS:-}" \
        CXXFLAGS="-march=x86-64-v3 -O2 -pipe ${CXXFLAGS:-}" \
            "${cmd[@]}"
    else
        "${cmd[@]}"
    fi
}

if [ "${USE_DOCKER}" -eq 1 ]; then
    log "Building inside Docker (archlinux:latest)..."
    DOCKER_SRCDEST="$(mktemp -d)"
    DOCKER_PKGDEST="$(mktemp -d)"
    trap 'rm -rf "${DOCKER_SRCDEST}" "${DOCKER_PKGDEST}"' EXIT

    # Stage: copy project + tarball into a build dir the container can see
    DOCKER_WORK="$(mktemp -d)"
    trap 'rm -rf "${DOCKER_WORK}"' EXIT
    cp -a "${SCRIPT_DIR}/cachyos" "${DOCKER_WORK}/"
    cp "${TARBALL}" "${DOCKER_WORK}/"

    docker run --rm \
        -v "${DOCKER_WORK}:/work" \
        -v "${DOCKER_SRCDEST}:/srcdest" \
        -v "${DOCKER_PKGDEST}:/pkgdest" \
        archlinux:latest \
        bash -c '
            set -e
            pacman -Sy --noconfirm --needed base-devel git && \
                useradd -m builder && chown -R builder:builder /work /srcdest /pkgdest && \
                sudo -u builder bash -c "
                    cd /work/cachyos && \
                    makepkg --syncdeps --noconfirm --nocheck --clean --skippgpcheck --skipinteg --holdver \
                        PKGDEST=/pkgdest SRCDEST=/srcdest
                "
        '
    # Copy the .pkg.tar.zst back
    find "${DOCKER_PKGDEST}" -name 'minimax-agent-*.pkg.tar.zst' -exec cp {} "${OUTPUT_DIR}/" \;
else
    log "Building on host ($(is_cachyos && echo Cachy || (is_arch && echo Arch || echo unknown)))..."
    command -v makepkg >/dev/null 2>&1 || \
        die "makepkg not found. Install: sudo pacman -S base-devel"

    # Install missing deps quietly
    if ! pacman -Qq base-devel >/dev/null 2>&1; then
        warn "base-devel not installed; will try to install via makepkg."
    fi

    # Run makepkg from the cachyos/ dir, with our tarball cached
    SRCDEST_STAGE="$(mktemp -d)"
    PKGDEST_STAGE="$(mktemp -d)"
    trap 'rm -rf "${SRCDEST_STAGE}" "${PKGDEST_STAGE}"' EXIT
    cp "${TARBALL}" "${SRCDEST_STAGE}/"

    ( cd "${PKG_DIR}" && \
      SRCDEST="${SRCDEST_STAGE}" \
      PKGDEST="${PKGDEST_STAGE}" \
      run_makepkg "${SRCDEST_STAGE}" "${PKGDEST_STAGE}" )

    find "${PKGDEST_STAGE}" -name 'minimax-agent-*.pkg.tar.zst' -exec cp {} "${OUTPUT_DIR}/" \;
fi

# ────────────────────────── verify + report ──────────────────────────
RESULT="${OUTPUT_DIR}/${PKG_NAME}"
if [ ! -f "${RESULT}" ]; then
    # fall back to whatever makepkg produced
    RESULT="$(ls -1t "${OUTPUT_DIR}"/minimax-agent-*.pkg.tar.zst 2>/dev/null | head -1 || true)"
fi

if [ -z "${RESULT}" ] || [ ! -f "${RESULT}" ]; then
    die "Package build failed — no .pkg.tar.zst produced."
fi

log "Package built: ${RESULT}"
log "Size: $(du -h "${RESULT}" | cut -f1)"

if command -v pacman >/dev/null 2>&1; then
    log "Package contents (top 20):"
    pacman -Qlp "${RESULT}" 2>/dev/null | head -20 || true
    log "Install with:"
    log "  sudo pacman -U ${RESULT}"
fi

log "Done."
