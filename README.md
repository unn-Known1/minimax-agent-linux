# MiniMax Agent for Linux

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Linux-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Architecture-amd64-orange" alt="Architecture">
  <img src="https://img.shields.io/badge/Version-3.0.68-green" alt="Version">
  <img src="https://img.shields.io/badge/Package-deb-red" alt="Package">
</p>

> **Note**: This is an **unofficial port** of MiniMax Agent for Linux. MiniMax does not currently offer an official Linux desktop application. This project aims to bring the MiniMax Agent experience to Linux users.

## Download .deb Package

**Direct Download:** Click on the `.deb` file in the `releases/` folder above, or use:
```bash
wget https://github.com/unn-Known1/minimax-agent-linux/releases/download/v3.0.68/minimax-agent_3.0.68_amd64.deb
```

## Installation

```bash
# Download the package
wget https://github.com/unn-Known1/minimax-agent-linux/releases/download/v3.0.68/minimax-agent_3.0.68_amd64.deb

# Install
sudo dpkg -i minimax-agent_3.0.68_amd64.deb

# Fix dependencies if needed
sudo apt --fix-broken install

# Run setup to download Electron runtime
sudo ./setup.sh

# Launch
minimax-agent
```

## Screenshots [ Working everything in new version ]

<p align="center">
  <img src="Screenshots/screenshot-01.png" alt="MiniMax Agent main interface" width="80%">
  <br/>
  <em>Main application interface</em>
</p>

<p align="center">
  <img src="Screenshots/screenshot-02.png" alt="Switch to Classic prompt" width="50%">
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
  <em>New mode requires a token plan (may be problem with the linux build!-known issue)</em>
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

- Linux Mint (primary tested)
- Ubuntu 20.04+
- Debian 10+
- Other Debian-based distributions with amd64 architecture

## System Requirements

### Minimum Requirements
- 64-bit (amd64) Linux distribution
- 2 GB RAM
- 1 GB free disk space
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

*Last updated: July 2026*
## Troubleshooting

### Backend service fails to start after login
- Ensure Node.js >= 18 is installed.
- Check daemon logs: `journalctl --user -u mavis.service` or `~/.mavis/logs/daemon-spawn.log`.
- If another daemon owns the data directory, restart the service or remove stale lock files under `~/.mavis`.
