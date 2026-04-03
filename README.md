# MiniMax Agent for Linux

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Linux-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Architecture-amd64-orange" alt="Architecture">
  <img src="https://img.shields.io/badge/Version-3.0.13-green" alt="Version">
  <img src="https://img.shields.io/badge/Package-deb-red" alt="Package">
</p>

> **Note**: This is an **unofficial community port** of MiniMax Agent for Linux. MiniMax does not currently offer an official Linux desktop application. This project aims to bring the MiniMax Agent experience to Linux users.

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

## Installation

### Method 1: Install Pre-built Package (Recommended)

1. Download the latest `.deb` package from the [Releases](https://github.com/unn-Known1/minimax-agent-linux/releases) page

2. Install using your package manager:

```bash
# Using dpkg directly
sudo dpkg -i minimax-agent_3.0.13_amd64.deb

# Or using gdebi (will handle dependencies automatically)
sudo apt install gdebi
sudo gdebi minimax-agent_3.0.13_amd64.deb
```

3. If you encounter dependency issues, run:
```bash
sudo apt --fix-broken install
```

### Method 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/unn-Known1/minimax-agent-linux.git
cd minimax-agent-linux

# Run the build script
chmod +x build.sh
sudo ./build.sh
```

## System Requirements

### Minimum Requirements
- 64-bit (amd64) Linux distribution
- 2 GB RAM
- 500 MB free disk space
- libgtk-3-0 and associated libraries

### Dependencies
The package will automatically install required dependencies including:
- libc6
- libnss3
- libx11-6
- libgtk-3-0
- libglib2.0-0
- libasound2
- Other X11 and system libraries

## Uninstallation

```bash
sudo dpkg -r minimax-agent
```

Or through your software center/package manager.

## Troubleshooting

### App shows blank screen or raw code
- Ensure you have the latest version installed
- Try clearing the app cache: `rm -rf ~/.config/minimax-agent`

### Google login doesn't complete
- Make sure `minimax://` protocol handler is registered
- Try logging out and back in
- Check that your firewall isn't blocking localhost connections

### Audio/video features not working
- Ensure PulseAudio or PipeWire is installed
- Check that your user has audio permissions

### App doesn't start
- Check logs at `~/.config/minimax-agent/logs/`
- Try running from terminal: `minimax-agent`

## Contributing

This is a community project to bring MiniMax Agent to Linux. Contributions are welcome!

### How You Can Help
- Test on different distributions and report issues
- Submit bug reports and feature requests
- Create installation guides for specific distributions
- Help improve the build process

## Disclaimer

This is an unofficial port. MiniMax is not affiliated with or endorse this project. This port was created to serve Linux users who want to use MiniMax Agent.

The original Windows application and its functionality belong to [MiniMax](https://www.minimax.io/).

## License

This project is released under the MIT license for the build scripts and packaging. The MiniMax Agent application itself remains the property of MiniMax.

## Links

- [Official MiniMax Agent Website](https://agent.minimax.io)
- [MiniMax Official Site](https://www.minimax.io/)
- [Report an Issue](https://github.com/unn-Known1/minimax-agent-linux/issues)

---

*Last updated: April 2026*
