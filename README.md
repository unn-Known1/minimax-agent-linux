# MiniMax Agent for Linux

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Linux-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Architecture-amd64-orange" alt="Architecture">
  <img src="https://img.shields.io/badge/Version-3.0.13-green" alt="Version">
  <img src="https://img.shields.io/badge/Package-deb-red" alt="Package">
</p>

> **Note**: This is an **unofficial community port** of MiniMax Agent for Linux. MiniMax does not currently offer an official Linux desktop application. This project aims to bring the MiniMax Agent experience to Linux users.

## Download .deb Package

**Direct Download:** Click on the `.deb` file in the `releases/` folder above, or use:
```bash
wget https://github.com/unn-Known1/minimax-agent-linux/raw/main/releases/minimax-agent_3.0.13_amd64.deb
```

## Installation

```bash
# Download the package
wget https://github.com/unn-Known1/minimax-agent-linux/raw/main/releases/minimax-agent_3.0.13_amd64.deb

# Install
sudo dpkg -i minimax-agent_3.0.13_amd64.deb

# Fix dependencies if needed
sudo apt --fix-broken install

# Launch
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

- Linux Mint (primary tested)
- Ubuntu 20.04+
- Debian 10+
- Other Debian-based distributions with amd64 architecture

## System Requirements

### Minimum Requirements
- 64-bit (amd64) Linux distribution
- 2 GB RAM
- 500 MB free disk space
- libgtk-3-0 and associated libraries

### Dependencies
The package will automatically install required dependencies.

## Uninstallation

```bash
sudo dpkg -r minimax-agent
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

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to help.

## Disclaimer

This is an unofficial port. MiniMax is not affiliated with this project. The original application belongs to [MiniMax](https://www.minimax.io/).

## Links

- [Official MiniMax Agent](https://agent.minimax.io)
- [Report an Issue](https://github.com/unn-Known1/minimax-agent-linux/issues)

---

*Last updated: April 2026*
