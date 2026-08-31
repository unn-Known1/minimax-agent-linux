# MiniMax Agent for Linux

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Linux-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Architecture-amd64-orange" alt="Architecture">
  <img src="https://img.shields.io/badge/Version-3.0.68-green" alt="Version">
  <img src="https://img.shields.io/badge/Packages-deb%20%7C%20pkg--tar--zst-red" alt="Packages">
</p>

> **Note**: This is an **unofficial port** of MiniMax Agent for Linux. MiniMax does not currently offer an official Linux desktop application. This project aims to bring the MiniMax Agent experience to Linux users.

---

## Quick Install

Pick your distribution:

### Debian / Ubuntu / Linux Mint (.deb)

```bash
wget https://github.com/unn-Known1/minimax-agent-linux/releases/download/v3.0.68/minimax-agent_3.0.68_amd64.deb
sudo dpkg -i minimax-agent_3.0.68_amd64.deb
sudo apt --fix-broken install
sudo ./setup.sh
minimax-agent
```

### Cachy OS / Arch / Manjaro (.pkg.tar.zst)

Cachy OS is a **first-class supported target** for this project. The package is built from a proper PKGBUILD (not a `debtap` conversion) and follows Cachy OS conventions: x86-64-v3 CFLAGS when the host supports them, dependency names matching the Arch repos, and an `install` hook that mirrors what the .deb's `postinst` does.

**Option A — one-liner (recommended):**
```bash
curl -fsSL https://raw.githubusercontent.com/unn-Known1/minimax-agent-linux/main/releases/download-cachyos.sh | sudo bash
minimax-agent
```

**Option B — manual install of the prebuilt package:**
```bash
wget https://github.com/unn-Known1/minimax-agent-linux/releases/download/v3.0.68/minimax-agent-3.0.68-1-x86_64.pkg.tar.zst
sudo pacman -U minimax-agent-3.0.68-1-x86_64.pkg.tar.zst
minimax-agent
```

**Option C — AUR helper (paru / yay):**

Once the package is on the AUR, you can install it like any other:
```bash
paru -S minimax-agent
# or
yay -S minimax-agent
```

> See [INSTALL.md](INSTALL.md) for the full Cachy OS / Arch install guide, including dependency details and post-install verification.

### Other Distributions

See [INSTALL.md](INSTALL.md) for Fedora/RHEL, openSUSE, NixOS, and source-build instructions.

---

## Screenshots

<p align="center">
  <img src="Screenshots/screenshot-01.png" alt="MiniMax Agent main interface" width="80%">
  <br/>
  <em>Main application interface</em>
</p>

<p align="center">
  <img src="Screenshots/screenshot-02.png" alt="Sign in Page" width="50%">
  <br/>
  <em>Sign in Page</em>
</p>

<p align="center">
  <img src="Screenshots/screenshot-03.png" alt="App running in Classic mode" width="80%">
  <br/>
  <em>Classic mode with credits</em>
</p>

<p align="center">
  <img src="Screenshots/screenshot-04.png" alt="Token plan restriction" width="80%">
  <br/>
  <em>New mode requires a token plan (may be problem with the linux build! — known issue)</em>
</p>

## Usage Notes

If you're using MiniMax Agent with **credits** and the app is not working in the default mode, try switching to **Classic** mode. The **New** mode may not work with credits alone (possibly requires a token plan, or it could be a Linux build limitation). Classic mode works fully with your existing credits.

- **Classic mode** — works with credits, fully functional
- **New mode** — may require a token plan or might be limited in the Linux build

Use the switch option in the app to toggle between modes.

## Features

- Full MiniMax Agent functionality
- Google OAuth login support
- Custom protocol handler (`minimax://`) for OAuth callbacks
- Desktop integration with app icons
- System tray support
- Daemon process for background tasks
- Skills and agents system
- All features from the Windows version

## Supported Distributions

| Distribution | Family | Package | Status |
|---|---|---|---|
| Linux Mint    | Debian | `.deb`  | Primary tested |
| Ubuntu 20.04+ | Debian | `.deb`  | Tested |
| Debian 11+    | Debian | `.deb`  | Tested |
| **Cachy OS**  | **Arch** | **`.pkg.tar.zst`** | **First-class (PKGBUILD-based)** |
| Arch Linux    | Arch   | `.pkg.tar.zst` | Tested (PKGBUILD-based) |
| Manjaro       | Arch   | `.pkg.tar.zst` | Should work (PKGBUILD-based) |
| EndeavourOS   | Arch   | `.pkg.tar.zst` | Should work (PKGBUILD-based) |
| Fedora        | RPM    | convert `.deb` via `alien` (legacy) | Best-effort |
| Other         | —      | source build | See INSTALL.md |

Cachy OS gets special treatment:
- Build auto-detects Cachy OS and applies x86-64-v3 CFLAGS where applicable
- `cachyos-ananicy-rules` and `cachyos-package-manager` are listed as `optdepends`
- The post-install hook prints a Cachy OS-specific hint when it runs on a Cachy OS host

## System Requirements

### Minimum Requirements
- 64-bit (amd64) Linux distribution
- 2 GB RAM
- 1 GB free disk space
- libgtk-3-0 and associated libraries (Debian) / gtk3 (Arch)

### Dependencies
The package will automatically install required dependencies.

## Uninstallation

```bash
# Debian/Ubuntu
sudo dpkg -r minimax-agent

# Cachy OS / Arch
sudo pacman -Rns minimax-agent
```

## Troubleshooting

### App shows blank screen
- Clear cache: `rm -rf ~/.config/minimax-agent`

### Google login doesn't complete
- Protocol handler should auto-register. If not:
```bash
# Debian
xdg-mime default minimax-agent.desktop x-scheme-handler/minimax
# Cachy OS / Arch — same command works
xdg-mime default minimax-agent.desktop x-scheme-handler/minimax
```

### Cachy OS / Arch: app doesn't start
- Check logs: `~/.mavis/logs/`
- Run from terminal: `minimax-agent`
- Verify dependencies: `pactree minimax-agent`
- Check the systemd user service: `systemctl --user status mavis.service`

### App doesn't start (general)
- Check logs: `~/.config/minimax-agent/logs/`
- Run from terminal: `minimax-agent`

## Building from Source

### Build the .deb (Debian/Ubuntu)
```bash
git clone https://github.com/unn-Known1/minimax-agent-linux.git
cd minimax-agent-linux
chmod +x build.sh
sudo ./build.sh
```

### Build the Cachy OS / Arch package

```bash
git clone https://github.com/unn-Known1/minimax-agent-linux.git
cd minimax-agent-linux

# On a Cachy OS / Arch host directly:
chmod +x build-cachyos.sh
./build-cachyos.sh

# Or in a Docker container from any Linux host:
./build-cachyos.sh --docker
```

Output: `releases/minimax-agent-<version>-<rel>-x86_64.pkg.tar.zst`

For AUR submission, see `cachyos/PKGBUILD` — it is structured for direct `makepkg --source` + `git push` to the AUR git server. The `.SRCINFO` is generated by `makepkg --printsrcinfo > .SRCINFO` (don't hand-edit it; see [AGENTS.md](AGENTS.md) for the release flow).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to help. Cachy OS is a great place to test — the AUR helper workflow (`paru -S minimax-agent`) and the x86-64-v3 optimization both need real-world validation.

## Disclaimer

This is an unofficial port. MiniMax is not affiliated with this project. The original application belongs to [MiniMax](https://www.minimax.io/).

## Links

- [Official MiniMax Agent](https://agent.minimax.io)
- [Report an Issue](https://github.com/unn-Known1/minimax-agent-linux/issues)

---

*Last updated: July 2026*

## Troubleshooting

### Backend service fails to start after login
- Ensure Node.js >= 18 is installed.
- Check daemon logs: `journalctl --user -u mavis.service` or `~/.mavis/logs/daemon-spawn.log`.
- If another daemon owns the data directory, restart the service or remove stale lock files under `~/.mavis`.
- On Cachy OS: ensure `loginctl show-user $USER | grep Linger` shows `Linger=yes` — the install hook enables this automatically, but it can be reset by some session managers.
