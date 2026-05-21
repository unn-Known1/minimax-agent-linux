# MiniMax Agent for Linux

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Linux-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Architecture-amd64-orange" alt="Architecture">
  <img src="https://img.shields.io/badge/Version-3.0.13-green" alt="Version">
  <img src="https://img.shields.io/badge/Package-deb%20%7C%20rpm-red" alt="Package">
</p>

> **Note**: This is an **unofficial community port** of MiniMax Agent for Linux. MiniMax does not currently offer an official Linux desktop application. This project aims to bring the MiniMax Agent experience to Linux users.

## Download Packages

Download the latest package from the [GitHub Releases](https://github.com/unn-Known1/minimax-agent-linux/releases) page:

- `.deb` for Ubuntu, Debian, Linux Mint, and other Debian-based distributions.
- `.rpm` for Fedora, RHEL-compatible distributions, and openSUSE.

Release packages are self-contained and include the Electron runtime and application payload.

## Installation

### Fedora/RHEL/openSUSE RPM

On desktop environments such as Fedora KDE Plasma or GNOME, download the `.rpm` release asset and double-click it to install with your graphical software installer.

If graphical installation is unavailable, install from a terminal instead:

**Fedora/RHEL:**
```bash
sudo dnf install ./minimax-agent-3.0.13-1.*.x86_64.rpm
```

**openSUSE:**
```bash
sudo zypper install ./minimax-agent-3.0.13-1.*.x86_64.rpm
```

### Ubuntu/Debian/Linux Mint DEB

```bash
sudo dpkg -i minimax-agent_3.0.13_amd64.deb
sudo apt --fix-broken install
```

Launch MiniMax Agent from your application menu, or run:

```bash
minimax-agent
```

## Features

- Full MiniMax Agent functionality
- Google OAuth login support
- Custom protocol handler (`minimax://`) for OAuth callbacks
- Desktop integration with app icons
- System tray support
- All features from the Windows version

## Supported Distributions

- Linux Mint
- Ubuntu 20.04+
- Debian 10+
- Fedora 38+; Fedora 44 KDE Plasma tested
- RHEL 9+
- openSUSE Tumbleweed / Leap
- Other Debian-based and RPM-based distributions with amd64 architecture

## System Requirements

### Minimum Requirements
- 64-bit (amd64) Linux distribution
- 2 GB RAM
- 500 MB free disk space
- libgtk-3-0 and associated libraries

### Dependencies
The package will automatically install required dependencies.

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

## Troubleshooting

### App shows blank screen
- Clear cache: `rm -rf ~/.config/minimax-agent`

### Google login doesn't complete
- Protocol handler should auto-register. If not:
```bash
xdg-mime default minimax-agent.desktop x-scheme-handler/minimax
```

### App doesn't start
- Check logs: `~/.config/minimax-agent/logs/`
- Run from terminal: `minimax-agent`

## Building from Source

```bash
git clone https://github.com/unn-Known1/minimax-agent-linux.git
cd minimax-agent-linux
chmod +x build.sh
sudo ./build.sh
```

## Building RPM Package

**Fedora/RHEL:**
```bash
sudo dnf install rpm-build rpmdevtools desktop-file-utils tar gzip
./build-rpm.sh
```

**openSUSE:**
```bash
sudo zypper install rpm-build desktop-file-utils tar gzip
./build-rpm.sh
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to help.

## Disclaimer

This is an unofficial port. MiniMax is not affiliated with this project. The original application belongs to [MiniMax](https://www.minimax.io/).

## Links

- [Official MiniMax Agent](https://agent.minimax.io)
- [Report an Issue](https://github.com/unn-Known1/minimax-agent-linux/issues)

---

*Last updated: April 2026*
