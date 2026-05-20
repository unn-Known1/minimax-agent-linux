#!/usr/bin/env bash
set -euo pipefail

rpm_file="${1:?Usage: tests/verify-rpm.sh path/to/minimax-agent.rpm}"

command -v rpm >/dev/null
command -v rpm2cpio >/dev/null
command -v cpio >/dev/null
command -v desktop-file-validate >/dev/null

test -f "$rpm_file"

rpm -qpi "$rpm_file"
rpm -qpl "$rpm_file"
rpm -qp --requires "$rpm_file"
rpm -qp --scripts "$rpm_file"

rpm -qpl "$rpm_file" | grep -qx "/usr/bin/minimax-agent"
rpm -qpl "$rpm_file" | grep -qx "/usr/share/applications/minimax-agent.desktop"
rpm -qpl "$rpm_file" | grep -q "^/opt/minimax-agent/"

rpm -qp --scripts "$rpm_file" | grep -q "update-desktop-database"
rpm -qp --scripts "$rpm_file" | grep -q "x-scheme-handler/minimax"
rpm -qp --scripts "$rpm_file" | grep -q "chrome-sandbox"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

(
  cd "$tmpdir"
  rpm2cpio "$rpm_file" | cpio -idmu --quiet
)

desktop-file-validate "$tmpdir/usr/share/applications/minimax-agent.desktop"

grep -q "MimeType=x-scheme-handler/minimax;x-scheme-handler/minimax-agent;" \
  "$tmpdir/usr/share/applications/minimax-agent.desktop"

test -x "$tmpdir/usr/bin/minimax-agent"

echo "RPM validation passed: $rpm_file"
