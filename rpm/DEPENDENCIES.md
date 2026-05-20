# RPM Dependency Mapping

This document maps Debian package dependencies to their RPM equivalents for Fedora/RHEL and openSUSE.

## Runtime Dependencies

| Debian dependency | Fedora/RHEL RPM package | openSUSE RPM package | Notes |
|---|---|---|---|
| `libc6 (>= 2.17)` | `glibc` | `glibc` | Base C runtime |
| `libnss3 (>= 3.14.3)` | `nss` | `mozilla-nss` | NSS runtime |
| `libx11-6` | `libX11` | `libX11-6` | X11 client library |
| `libx11-xcb1` | `libX11-xcb` | `libX11-xcb1` | XCB interop |
| `libxcb1` | `libxcb` | `libxcb1` | X protocol C binding |
| `libxcomposite1` | `libXcomposite` | `libXcomposite1` | X composite extension |
| `libxdamage1` | `libXdamage` | `libXdamage1` | X damage extension |
| `libxext6` | `libXext` | `libXext6` | X extensions |
| `libxfixes3` | `libXfixes` | `libXfixes3` | X fixes extension |
| `libxrandr2` | `libXrandr` | `libXrandr2` | X randr extension |
| `libxrender1` | `libXrender` | `libXrender1` | X render extension |
| `libxss1` | `libXScrnSaver` | `libXss1` | Screen saver extension |
| `libxtst6` | `libXtst` | `libXtst6` | X test extension |
| `libglib2.0-0` | `glib2` | `libglib-2_0-0` | GLib runtime |
| `libgtk-3-0` | `gtk3` | `gtk3` | GTK 3 runtime |
| `libnotify4` | `libnotify` | `libnotify4` | Desktop notifications |
| `libnspr4` | `nspr` | `mozilla-nspr` | Netscape Portable Runtime |
| `libdbus-1-3` | `dbus-libs` | `libdbus-1-3` | D-Bus runtime library |
| `libdrm2` | `libdrm` | `libdrm2` | DRM library |
| `libgbm1` | `mesa-libgbm` | `libgbm1` | GBM/Mesa |
| `libasound2` | `alsa-lib` | `alsa-lib` | ALSA audio |

## Build Dependencies

| Purpose | Fedora/RHEL package | openSUSE package |
|---|---|---|
| RPM build | `rpm-build`, `rpmdevtools` | `rpm-build` |
| Desktop validation | `desktop-file-utils` | `desktop-file-utils` |
| Protocol registration | `xdg-utils` | `xdg-utils` |
| RPM linting | `rpmlint` | `rpmlint` |

## Notes

- RPM may auto-detect ELF shared library requirements. Explicit runtime dependencies should be pruned only after install tests prove they are unnecessary.
- The `chrome-sandbox` binary requires special permission handling. See the spec file for conditional SUID logic based on user namespace availability.
