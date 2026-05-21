# Installation Guide

This guide explains how to install MiniMax Agent for Linux from the self-contained release packages.

## Download

Download the latest package from the [GitHub Releases](https://github.com/unn-Known1/minimax-agent-linux/releases) page:

- `.deb` for Ubuntu, Debian, Linux Mint, and other Debian-based distributions.
- `.rpm` for Fedora, RHEL-compatible distributions, and openSUSE.

The release packages include the Electron runtime and application payload. You do not need to download runtime assets separately.

## Fedora/RHEL/openSUSE RPM Installation

### Graphical install

On desktop environments such as Fedora KDE Plasma or GNOME, download the `.rpm` release asset and double-click it. Your software installer should open and guide you through installation.

This flow was tested on Fedora 44 KDE Plasma.

### Terminal fallback

If graphical installation is unavailable, install the RPM from a terminal.

**Fedora/RHEL:**
```bash
sudo dnf install ./minimax-agent-3.0.13-1.*.x86_64.rpm
```

**openSUSE:**
```bash
sudo zypper install ./minimax-agent-3.0.13-1.*.x86_64.rpm
```

## Ubuntu/Debian/Linux Mint DEB Installation

```bash
sudo dpkg -i minimax-agent_3.0.13_amd64.deb
sudo apt --fix-broken install
```

## Launch

You can launch MiniMax Agent from:

- Your application menu.
- The desktop icon, if your environment creates one.
- A terminal:

```bash
minimax-agent
```

## File Locations

After installation:

- Application binary: `/opt/minimax-agent/electron`
- Resources: `/opt/minimax-agent/resources/`
- Desktop file: `/usr/share/applications/minimax-agent.desktop`
- Launcher: `/usr/bin/minimax-agent`

## Verify Protocol Handler

The package registers the `minimax://` and `minimax-agent://` protocol handlers for OAuth callbacks.

```bash
xdg-mime query default x-scheme-handler/minimax
xdg-mime query default x-scheme-handler/minimax-agent
```

Expected result:

```text
minimax-agent.desktop
```

If either handler is missing, register it manually:

```bash
xdg-mime default minimax-agent.desktop x-scheme-handler/minimax
xdg-mime default minimax-agent.desktop x-scheme-handler/minimax-agent
```

## Troubleshooting

### Command not found after installation

Log out and log back in, or refresh your shell command cache:

```bash
hash -r
```

### App does not start

Run the launcher from a terminal to see startup logs:

```bash
minimax-agent
```

You can also check whether the Electron runtime is installed:

```bash
ls -la /opt/minimax-agent/electron
```

### Google login fails

Check protocol handler registration with the commands in [Verify Protocol Handler](#verify-protocol-handler).

## Uninstallation

**Ubuntu/Debian/Linux Mint:**
```bash
sudo dpkg -r minimax-agent
```

**Fedora/RHEL:**
```bash
sudo dnf remove minimax-agent
```

**openSUSE:**
```bash
sudo zypper remove minimax-agent
```

After uninstallation, optionally clean up local application files:

```bash
sudo rm -rf /opt/minimax-agent
sudo rm -rf /var/cache/minimax-agent
```
