#!/bin/bash
# MiniMax Agent Linux Build Script
# This script builds the .deb package from the source files

set -e

VERSION="3.0.68"
ARCH="amd64"
# Must match setup.sh's ELECTRON_VERSION. Used for @electron/rebuild.
ELECTRON_VERSION="35.7.0"

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
echo "[1/6] Checking build dependencies..."
MISSING_TOOLS=()
command -v dpkg-deb >/dev/null 2>&1 || MISSING_TOOLS+=("dpkg-dev")
command -v fakeroot >/dev/null 2>&1 || MISSING_TOOLS+=("fakeroot")
command -v npm >/dev/null 2>&1 || MISSING_TOOLS+=("npm")
command -v npx >/dev/null 2>&1 || MISSING_TOOLS+=("npx")

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "Missing tools: ${MISSING_TOOLS[*]}"
    echo "Install them with: sudo apt install ${MISSING_TOOLS[*]}"
    exit 1
fi

echo "  All dependencies satisfied."

# Clean previous builds with safety checks
echo ""
echo "[2/6] Cleaning previous builds..."
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

# Ensure resources are in place
RELEASE_DIR="/tmp/minimax-app/resources"
ASAR_UNPACKED_SRC="$RELEASE_DIR/app.asar.unpacked"
ASAR_UNPACKED_DST="$BUILD_DIR/opt/minimax-agent/resources/app.asar.unpacked"

echo ""

echo "[3/6] Preparing native modules..."

# 1. Copy app.asar from Windows release source if present
if [ ! -f "$BUILD_DIR/opt/minimax-agent/resources/app.asar" ]; then
    if [ -f "$RELEASE_DIR/app.asar" ]; then
        echo "  Copying app.asar from Windows release..."
        cp "$RELEASE_DIR/app.asar" "$BUILD_DIR/opt/minimax-agent/resources/app.asar"
    else
        echo "  WARNING: app.asar not found at $RELEASE_DIR"
        echo "  Run the extract step to unpack the Windows installer first."
    fi
fi

# 2. Copy app.asar.unpacked (native modules) from Windows release
if [ ! -d "$ASAR_UNPACKED_DST" ]; then
    if [ -d "$ASAR_UNPACKED_SRC" ]; then
        echo "  Copying app.asar.unpacked from Windows release..."
        cp -r "$ASAR_UNPACKED_SRC" "$ASAR_UNPACKED_DST"
    else
        echo "  WARNING: app.asar.unpacked not found at $ASAR_UNPACKED_SRC"
    fi
fi

# 2b. Inject @vscode/ripgrep-linux-x64 into app.asar (idempotent).
# The wrapper at app.asar/node_modules/@vscode/ripgrep/lib/index.js calls
# require.resolve('@vscode/ripgrep-linux-x64/bin/rg'), which Node's module
# resolver walks from inside the asar. app.asar.unpacked/ is not on that
# walk path (Electron exposes .unpacked to fs / dlopen only), so the
# platform package must live INSIDE the asar's node_modules.
#
# @electron/asar extract reads files marked as "unpacked" in the asar header
# from a sibling .unpacked/ directory. The Windows installer ships that
# directory with only Windows native binaries, so references to darwin-arm64,
# win32-arm64, libnut-linux, etc. are missing on disk and abort extraction.
# We extract the file list via the @electron/asar API, stub any missing
# unpacked files with empty placeholders, extract, then delete the stubs
# (0-byte files) before repacking so they don't poison the new asar.
echo "[3.5/6] Ensuring platform-specific packages in app.asar..."
ASAR_PATH="$BUILD_DIR/opt/minimax-agent/resources/app.asar"
if [ ! -f "$ASAR_PATH" ]; then
    echo "  ERROR: $ASAR_PATH not found. Copy resources before building."
    exit 1
fi

# Idempotency: detect what is already present.
HAS_RG=$(npx --yes @electron/asar list "$ASAR_PATH" 2>/dev/null \
         | grep -c '^/node_modules/@vscode/ripgrep-linux-x64/' || true)

# Linux-native packages whose JS is in the asar but whose Linux .node
# binaries were never shipped (Windows installer only includes Windows
# natives). Extend this list when runtime reports a missing native.
NATIVE_PKGS=(
    "@nut-tree/libnut-linux"
    "node-pty"
    "node-screenshots"
)

# Always install natives on every build. npm install + rebuild takes
# ~30s; idempotent because cp -a overwrites the same paths each time.
NEEDS_NATIVES=1

if [ "$HAS_RG" -gt 0 ] && [ "$NEEDS_NATIVES" -eq 0 ]; then
    echo "  All platform packages present; skipping."
else
    echo "  Injecting ripgrep + Linux natives..."

    TMPDIR=$(mktemp -d /tmp/asar-repack-XXXXXX)
    UNPACKED_BASE="$ASAR_PATH.unpacked"

    # Extract the asar via the @electron/asar API: walk the recursive
    # header tree, extract packed files via extractFile(), copy unpacked
    # files from .unpacked/, and stub any unpacked files that are
    # missing on disk (Windows installer only ships Windows natives).
    TOOLS=$(mktemp -d /tmp/asar-tools-XXXXXX)
    ( cd "$TOOLS" && npm init -y >/dev/null 2>&1 && npm install --no-audit --no-fund @electron/asar 2>&1 | tail -2 )
    ASAR_FOR_NODE="$ASAR_PATH" \
    UNPACKED_FOR_NODE="$UNPACKED_BASE" \
    DEST_FOR_NODE="$TMPDIR/extracted" \
    NODE_PATH="$TOOLS/node_modules" \
    node -e "
        const { getRawHeader, extractFile } = require('@electron/asar');
        const fs = require('fs');
        const path = require('path');
        const ASAR = process.env.ASAR_FOR_NODE;
        const UNPACKED_BASE = process.env.UNPACKED_FOR_NODE;
        const DEST = process.env.DEST_FOR_NODE;
        fs.mkdirSync(DEST, { recursive: true });
        const { header } = getRawHeader(ASAR);
        let packed = 0, copied = 0, stubbed = 0, errors = 0;
        (function walk(node, base) {
            for (const name of Object.keys(node.files || {})) {
                const full = base ? base + '/' + name : name;
                const child = node.files[name];
                if (child.files) {
                    fs.mkdirSync(path.join(DEST, full), { recursive: true });
                    walk(child, full);
                } else {
                    const dest = path.join(DEST, full);
                    fs.mkdirSync(path.dirname(dest), { recursive: true });
                    if (child.unpacked) {
                        const src = path.join(UNPACKED_BASE, full);
                        if (fs.existsSync(src)) {
                            fs.copyFileSync(src, dest);
                            copied++;
                        } else {
                            fs.writeFileSync(dest, '');
                            stubbed++;
                        }
                    } else {
                        try {
                            fs.writeFileSync(dest, extractFile(ASAR, full));
                            packed++;
                        } catch (e) {
                            errors++;
                            if (errors <= 3) console.error('  WARN: failed to extract', full, '-', e.message);
                        }
                    }
                }
            }
        })(header, '');
        console.log('  Extracted', packed, 'packed,', copied, 'unpacked,', stubbed, 'stubbed,', errors, 'errors');
    " || { rm -rf "$TMPDIR" "$TOOLS"; exit 1; }
    rm -rf "$TOOLS"

    # Install @vscode/ripgrep-linux-x64 via npm if missing. The wrapper at
    # app.asar/node_modules/@vscode/ripgrep/lib/index.js calls
    # require.resolve('@vscode/ripgrep-linux-x64/bin/rg'), which Node's
    # module resolver walks from inside the asar — so the package must
    # live INSIDE the asar's node_modules.
    if [ "$HAS_RG" -eq 0 ]; then
        STAGE=$(mktemp -d /tmp/asar-stage-XXXXXX)
        ( cd "$STAGE"
          printf '{"name":"backfill","version":"1.0.0","private":true,"dependencies":{"@vscode/ripgrep":"*"}}\n' > package.json
          npm install --no-audit --no-fund --omit=dev 2>&1 | tail -3 )
        if [ ! -d "$STAGE/node_modules/@vscode/ripgrep-linux-x64" ]; then
            echo "  ERROR: npm install @vscode/ripgrep failed."
            rm -rf "$TMPDIR" "$STAGE"
            exit 1
        fi
        mkdir -p "$TMPDIR/extracted/node_modules/@vscode"
        cp -a "$STAGE/node_modules/@vscode/ripgrep-linux-x64" \
              "$TMPDIR/extracted/node_modules/@vscode/"
        rm -rf "$STAGE"
    fi

    # Install Linux natives for any missing native packages. Each package
    # is installed in its own temp dir so a 404 on one doesn't block the
    # others. Then prebuild-install rebuilds for Electron 33 ABI (build
    # host runs Node 22 ABI 127; Electron 33 needs ABI 130). Repack below
    # moves .node/.so/.dylib to .unpacked/.
    #
    # @nut-tree/libnut-linux is the name in the asar, but the original
    # upstream was abandoned; the actively-maintained fork is
    # @nut-tree-fork/libnut-linux. We install the fork and copy its
    # contents over the asar's @nut-tree/libnut-linux/ directory (the
    # fork's index.js is identical, drop-in compatible).
    asar_to_npm() {
        case "$1" in
            "@nut-tree/libnut-linux") echo "@nut-tree-fork/libnut-linux" ;;
            *) echo "$1" ;;
        esac
    }
    if [ "$NEEDS_NATIVES" -eq 1 ]; then
        for asar_pkg in "${NATIVE_PKGS[@]}"; do
            npm_pkg=$(asar_to_npm "$asar_pkg")
            PKG_TMP=$(mktemp -d /tmp/native-pkg-XXXXXX)
            (
                cd "$PKG_TMP"
                printf '{"name":"backfill","version":"1.0.0","private":true,"dependencies":{"%s":"*"}}\n' \
                       "$npm_pkg" > package.json
                # --ignore-scripts so the host doesn't compile a wrong-ABI
                # .node first; @electron/rebuild below does the right build.
                npm install --ignore-scripts --no-audit --no-fund --omit=dev 2>&1 | tail -3
            ) || { echo "  WARN: npm install $npm_pkg failed; skipping"; rm -rf "$PKG_TMP"; continue; }

            # Rebuild .node/.so for Electron 33 ABI (npm fetched for host ABI).
            pkg_dir="$PKG_TMP/node_modules/$npm_pkg"
            if [ ! -d "$pkg_dir" ]; then
                echo "  WARN: $npm_pkg did not produce a directory; skipping"
                rm -rf "$PKG_TMP"
                continue
            fi
            echo "  Rebuilding $npm_pkg for Electron v${ELECTRON_VERSION} ABI..."
            # Adopt the better-sqlite3 pattern: npm install --ignore-scripts
            # (so the host doesn't build a wrong-ABI .node first), then
            # @electron/rebuild compiles for Electron 33. N-API modules are
            # ABI-stable, so a Node 22 build would still load — but we rebuild
            # for consistency with the existing better-sqlite3 flow.
            PB_LOG="$PKG_TMP/rebuild.log"
            ( cd "$pkg_dir" && \
              npx --yes @electron/rebuild -o "$npm_pkg" -v "${ELECTRON_VERSION}" -f ) >"$PB_LOG" 2>&1 || \
                { echo "  WARN: rebuild for $npm_pkg failed"; tail -5 "$PB_LOG" | sed 's/^/    /'; }

            # Copy main package to the asar's path. `cp -a src dst` nests
            # src inside dst if dst exists; rm first to ensure a clean
            # replacement (otherwise we get pkg/pkg/.node on second build).
            if [[ "$asar_pkg" == @*/* ]]; then
                dest="$TMPDIR/extracted/node_modules/${asar_pkg%%/*}/${asar_pkg#*/}"
            else
                dest="$TMPDIR/extracted/node_modules/$asar_pkg"
            fi
            rm -rf "$dest"
            mkdir -p "$(dirname "$dest")"
            cp -a "$pkg_dir" "$dest"

            # Copy any optional linux-* platform subpackage (e.g.
            # node-screenshots-linux-x64-gnu, which is an optionalDep of
            # node-screenshots and contains the actual .node binary).
            for opt in "$PKG_TMP/node_modules"/@*/*/linux-* "$PKG_TMP/node_modules"/*linux-*; do
                [ -d "$opt" ] || continue
                optname="$(basename "$opt")"
                optdest="$TMPDIR/extracted/node_modules/$optname"
                rm -rf "$optdest"
                cp -a "$opt" "$optdest"
            done

            rm -rf "$PKG_TMP"
        done
    fi

    # Delete the 0-byte stubs before repacking so they aren't referenced
    # as unpacked entries in the new asar (which would break the next extract).
    find "$TMPDIR/extracted" -type f -size 0 -delete 2>/dev/null || true

    # Repack with the same unpacked patterns electron-builder uses by default.
    TOOLS=$(mktemp -d /tmp/asar-tools-XXXXXX)
    ( cd "$TOOLS" && npm init -y >/dev/null 2>&1 && npm install --no-audit --no-fund @electron/asar 2>&1 | tail -2 )
    ASAR_FOR_NODE="$TMPDIR/extracted" \
    OUT_FOR_NODE="$ASAR_PATH.new" \
    NODE_PATH="$TOOLS/node_modules" \
    node -e "
        const { createPackageWithOptions } = require('@electron/asar');
        const fs = require('fs');
        createPackageWithOptions(process.env.ASAR_FOR_NODE, process.env.OUT_FOR_NODE, {
            unpack: '*.{node,so,dylib}',
        }).then(() => {
            console.log('  Repacked:', fs.statSync(process.env.OUT_FOR_NODE).size, 'bytes');
        });
    " || { rm -rf "$TMPDIR" "$TOOLS" "$ASAR_PATH.new"; exit 1; }
    rm -rf "$TOOLS"
    mv "$ASAR_PATH.new" "$ASAR_PATH"
    # `mv src dst` into an existing dir nests src inside dst; we need to
    # REPLACE the unpacked dir so the new natives land at the expected path.
    rm -rf "$ASAR_PATH.unpacked"
    mv "$ASAR_PATH.new.unpacked" "$ASAR_PATH.unpacked"
    rm -rf "$TMPDIR"
    echo "  Done."
fi

# 3. Rebuild better-sqlite3 for Electron's Node.js ABI if source is available
if [ -d "$ASAR_UNPACKED_DST/node_modules/better-sqlite3" ]; then
    echo "  Rebuilding better-sqlite3 for Electron v${ELECTRON_VERSION} ABI..."
    cd "$ASAR_UNPACKED_DST/node_modules/better-sqlite3"
    if command -v npx >/dev/null 2>&1; then
        # Try prebuild-install first (downloads prebuilt linux binary)
        npx --yes prebuild-install 2>/dev/null || true
        
        # Check if the module loads with Electron
        if ELECTRON_RUN_AS_NODE=1 /opt/minimax-agent/electron -e \
            "try { require('./build/Release/better_sqlite3.node'); console.log('OK'); } catch(e) { console.log('NEEDS_REBUILD'); }" 2>/dev/null | grep -q "OK"; then
            echo "  better-sqlite3 native module OK."
        else
            echo "  Rebuilding better-sqlite3 for Electron ABI..."
            # Install better-sqlite3 fresh in temp dir and rebuild for Electron
            TEMP_DIR="/tmp/electron-rebuild-temp"
            rm -rf "$TEMP_DIR"
            mkdir -p "$TEMP_DIR"
            cat > "$TEMP_DIR/package.json" << 'TMPJSON'
{
  "name": "electron-rebuild-temp",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "better-sqlite3": "12.11.1"
  }
}
TMPJSON
            cd "$TEMP_DIR"
            npm install --ignore-scripts 2>/dev/null
            npx @electron/rebuild -o better-sqlite3 -v "${ELECTRON_VERSION}" -f 2>&1
            if [ -f "$TEMP_DIR/node_modules/better-sqlite3/build/Release/better_sqlite3.node" ]; then
                cp "$TEMP_DIR/node_modules/better-sqlite3/build/Release/better_sqlite3.node" \
                   "$ASAR_UNPACKED_DST/node_modules/better-sqlite3/build/Release/better_sqlite3.node"
                echo "  better-sqlite3 rebuilt for Electron ABI."
            fi
            rm -rf "$TEMP_DIR"
        fi
    fi
    cd "$SCRIPT_DIR"
fi
echo "  Native modules ready."

# Build the package
echo ""
echo "[4/6] Building package..."
GZIP=-1 dpkg-deb -Zgzip -z1 --build "$BUILD_DIR" "$OUTPUT_DIR/$PACKAGE_NAME"

# Verify the package
echo ""
echo "[5/6] Verifying package..."
if [ -f "$OUTPUT_DIR/$PACKAGE_NAME" ]; then
    echo "  Package created successfully!"
    ls -lh "$OUTPUT_DIR/$PACKAGE_NAME"
    echo ""
    echo "  Install with: sudo dpkg -i $OUTPUT_DIR/$PACKAGE_NAME"
else
    echo "  Error: Package creation failed!"
    exit 1
fi

# Verify the daemon starts correctly
echo ""
echo "[6/6] Verifying daemon startup..."
DAEMON_JS="$BUILD_DIR/opt/minimax-agent/resources/resources/daemon/daemon.js"
if [ -f "$DAEMON_JS" ]; then
    echo "  Daemon entry point found."
    echo "  Install the .deb to test: sudo dpkg -i $OUTPUT_DIR/$PACKAGE_NAME"
else
    echo "  Error: Daemon entry point not found!"
    exit 1
fi

echo ""
echo "=========================================="
echo "  Build Complete!"
echo "=========================================="
