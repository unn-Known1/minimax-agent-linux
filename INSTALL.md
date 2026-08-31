# Installation Guide

This guide explains how to install the MiniMax Agent for Linux on every supported distribution family.

> **TL;DR**
> - Debian/Ubuntu: `dpkg -i ...` then `apt --fix-broken install`
> - **Cachy OS / Arch: `pacman -U ...` (or `paru -S minimax-agent` once AUR-published)**
> - Other: see the source-build section at the bottom

---

## Table of Contents

- [Cachy OS / Arch / Manjaro](#cachy-os--arch--manjaro) — first-class supported
- [Debian / Ubuntu / Linux Mint](#debian--ubuntu--linux-mint) — .deb package
- [Fedora / RHEL](#fedora--rhel) — convert .deb via `alien` (best-effort)
- [Building from source](#building-from-source)
- [Verifying the install](#verifying-the-install)
- [Uninstalling](#uninstalling)

---

## Cachy OS / Arch / Manjaro

Cachy OS is an **Arch-based distribution** that uses `pacman`. The same `.pkg.tar.zst` package works on:

- Cachy OS (any edition)
- Arch Linux (rolling)
- Manjaro
- EndeavourOS
- Garuda
- Artix
- Other Arch-derivatives

The package is built from a real `PKGBUILD` (not a `debtap` conversion), with Arch-native dependency names, an `install` hook, and Cachy OS-aware CFLAGS (x86-64-v3 when the host supports it).

### Prerequisites

Make sure you have:

- `pacman` (obviously — preinstalled on all Arch-based systems)
- `curl` or `wget`
- `sudo` or root access
- An active user account (the install hook sets up per-user dirs)
- Node.js **>= 18** for the backend daemon:
  ```bash
  sudo pacman -S nodejs npm
  ```
- `xdg-utils`, `gtk-update-icon-cache`, and `systemd` (all preinstalled on Cachy OS)

### Method 1 — One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/unn-Known1/minimax-agent-linux/main/releases/download-cachyos.sh | sudo bash
```

The script:
1. Detects your distro
2. Fetches the latest release's `.pkg.tar.zst` (and its `SHA256SUMS` for verification)
3. Verifies the SHA256
4. Runs `pacman -U` to install
5. Prints post-install instructions

### Method 2 — Manual download + install

1. Go to the [latest release page](https://github.com/unn-Known1/minimax-agent-linux/releases/latest).
2. Download the file matching `minimax-agent-<version>-1-x86_64.pkg.tar.zst`:
   ```bash
   wget https://github.com/unn-Known1/minimax-agent-linux/releases/download/v3.0.68/minimax-agent-3.0.68-1-x86_64.pkg.tar.zst
   ```
3. Install with pacman:
   ```bash
   sudo pacman -U minimax-agent-3.0.68-1-x86_64.pkg.tar.zst
   ```
   Pacman will resolve and pull in any missing dependencies (gtk3, nss, libx11, etc.) automatically.

### Method 3 — AUR helper (paru / yay)

Once the package is published to the AUR, you can install it just like any other user package:

```bash
paru -S minimax-agent
# or
yay -S minimax-agent
```

> AUR publication happens once the PKGBUILD passes community review. See `cachyos/PKGBUILD` and the `AGENTS.md` "AUR submission" section for the procedure.

### Method 4 — Build from source

See [Building from source](#building-from-source) below.

### What the install hook does

The package's `install` script (`cachyos/minimax-agent.install`) is run by pacman at install / upgrade / remove time. It:

- Sets the `chrome-sandbox` SUID bit at `/opt/minimax-agent/chrome-sandbox`
- Refreshes the hicolor icon cache and `update-desktop-database`
- Registers `x-scheme-handler/minimax` and `x-scheme-handler/minimax-agent` to `minimax-agent.desktop` via `xdg-mime` and `gio`
- Walks `/etc/passwd` and creates `$HOME/.mavis/{logs,screenshots}` for every human user, with the right ownership
- Enables systemd user linger for every human user (so `mavis.service` survives logout)
- Rebuilds `better-sqlite3` / `fs-native-extensions` against the system's Node.js if needed
- Prints a Cachy OS-specific hint (suggesting `cachyos-ananicy-rules` and `cachyos-package-manager`) when it detects a Cachy OS host

### Cachy OS–specific tips

- **Performance**: install `cachyos-ananicy-rules` for better process scheduling. The package lists it as an optdepend.
- **Cflags**: if you want to recompile the bundled native modules with x86-64-v3 (Cachy OS default), the PKGBUILD's `CFLAGS` block already does this. You can force it explicitly with `./build-cachyos.sh --v3`.
- **Pacman hooks**: no special hooks are required. The standard `install` script runs at install time.
- **Aur helpers**: `paru` is in the Cachy OS repos (`sudo pacman -S paru`).

### Cachy OS troubleshooting

**"error: failed to prepare transaction (could not satisfy dependencies)"**

You're missing one or more of the runtime dependencies. Install them:
```bash
sudo pacman -S gtk3 nss libx11 libxcb libxcomposite libxdamage libxext \
              libxfixes libxrandr libxrender libxss libxtst glib2 libnotify \
              nspr dbus libdrm mesa alsa-lib nodejs npm
```

**"command not found: minimax-agent" after install**

Log out and back in (so your shell rehashes `/usr/bin/`), or:
```bash
hash -r
```

**Backend daemon fails to start**

```bash
# 1. Check that Node.js is recent enough
node --version   # must be >= 18

# 2. Check the user service
systemctl --user status mavis.service

# 3. Check daemon logs
journalctl --user -u mavis.service -n 50
# or
cat ~/.mavis/logs/daemon-spawn.log

# 4. Try rebuilding native modules manually
cd /opt/minimax-agent/resources/resources/daemon
npm rebuild
```

**App is slow / first launch is sluggish**

This is the Electron runtime initializing. On Cachy OS you can pre-warm the OS page cache:
```bash
sudo pacman -S cachyos-ananicy-rules && sudo systemctl enable --now ananicy
```

**Google login fails (OAuth callback)**

```bash
xdg-mime query default x-scheme-handler/minimax
# should return: minimax-agent.desktop
```

If not:
```bash
xdg-mime default minimax-agent.desktop x-scheme-handler/minimax
xdg-mime default minimax-agent.desktop x-scheme-handler/minimax-agent
```

---

## Debian / Ubuntu / Linux Mint

### Prerequisites

```bash
sudo apt update
sudo apt install wget curl unzip libgtk-3-0 libnss3 libasound2 libxss1 libgbm1 nodejs npm
```

### Full Installation Steps

#### Step 1 — Install the .deb Package

```bash
sudo dpkg -i minimax-agent_3.0.68_amd64.deb
sudo apt --fix-broken install
```

#### Step 2 — Download and Setup Electron Runtime

```bash
sudo ./setup.sh
```

#### Step 3 — Install Daemon Dependencies

If setup.sh didn't run npm install automatically:

```bash
cd /opt/minimax-agent/resources/resources/daemon
sudo npm install --omit=dev
```

#### Step 4 — (Optional) Install OpenCode

Place the Linux `opencode` binary at:
```
/opt/minimax-agent/resources/resources/opencode/opencode
```

#### Step 5 — Launch

You can launch MiniMax Agent from:
- Application menu
- Terminal: `minimax-agent`

### File Locations

After installation:
- Application binary: `/opt/minimax-agent/electron`
- App code: `/opt/minimax-agent/resources/app.asar`
- Daemon: `/opt/minimax-agent/resources/resources/daemon/`
- Desktop file: `/usr/share/applications/minimax-agent.desktop`
- Launcher: `/usr/bin/minimax-agent`

### Debian / Ubuntu Troubleshooting

**"Command not found" after installation**

Log out and log back in, or run:
```bash
hash -r
```

**App doesn't start**

Check if Electron is present:
```bash
ls -la /opt/minimax-agent/electron
```

If missing, re-run setup.sh.

**Google login fails**

Check protocol handler registration:
```bash
xdg-mime query default x-scheme-handler/minimax
```

Should return: `minimax-agent.desktop`

If not, run:
```bash
xdg-mime default minimax-agent.desktop x-scheme-handler/minimax
xdg-mime default minimax-agent.desktop x-scheme-handler/minimax-agent
```

---

## Fedora / RHEL

This project targets Debian and Arch. For Fedora, convert the .deb via `alien`:

```bash
sudo dnf install alien
sudo alien -r minimax-agent_3.0.68_amd64.deb
sudo dnf install ./minimax-agent-3.0.68.x86_64.rpm
```

> **Note**: the resulting RPM is best-effort. For best results on Fedora, file an issue and we'll add a proper spec file.

---

## Building from source

### Build the .deb (any Linux with dpkg-deb)

```bash
git clone https://github.com/unn-Known1/minimax-agent-linux.git
cd minimax-agent-linux
chmod +x build.sh
sudo ./build.sh
```

Output: `output/minimax-agent_<version>_amd64.deb`

### Build the Cachy OS / Arch package

The `build-cachyos.sh` script handles both native builds and Docker-based cross-builds.

**On a Cachy OS / Arch host (recommended):**
```bash
chmod +x build-cachyos.sh
./build-cachyos.sh
```

**In a Docker container (any Linux host):**
```bash
./build-cachyos.sh --docker
```

**Force x86-64-v3 CFLAGS (Cachy OS optimization):**
```bash
./build-cachyos.sh --v3
```

**Clean previous build artifacts:**
```bash
./build-cachyos.sh --clean
```

Output: `releases/minimax-agent-<version>-<rel>-x86_64.pkg.tar.zst`

### Building the PKGBUILD directly (for AUR)

```bash
cd cachyos
makepkg -si    # build + install deps + install
```

To submit to the AUR, see `AGENTS.md`.

---

## Verifying the install

After installation (any distro), confirm:

```bash
# 1. Binary is on PATH
which minimax-agent
# Expected: /usr/bin/minimax-agent

# 2. Package is registered
# Debian
dpkg -l minimax-agent
# Arch
pacman -Qi minimax-agent

# 3. Desktop file is in place
ls -la /usr/share/applications/minimax-agent.desktop

# 4. App data is installed
ls /opt/minimax-agent/

# 5. Launch and check it runs
minimax-agent
```

---

## Uninstalling

```bash
# Debian/Ubuntu
sudo dpkg -r minimax-agent
sudo rm -rf /opt/minimax-agent
sudo rm -rf /var/cache/minimax-agent

# Cachy OS / Arch (with config cleanup)
sudo pacman -Rns minimax-agent
sudo rm -rf /opt/minimax-agent
sudo rm -rf /var/cache/minimax-agent

# Per-user data (both distros)
rm -rf ~/.config/minimax-agent
rm -rf ~/.mavis
```
