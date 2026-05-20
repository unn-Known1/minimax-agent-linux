# Contributing to MiniMax Agent Linux

Thank you for your interest in contributing to the MiniMax Agent Linux port!

## How to Contribute

### Reporting Issues

1. **Check existing issues** - Before creating a new issue, please search to see if it's already reported
2. **Include system information**:
   - Distribution and version (e.g., Linux Mint 21.2)
   - Desktop environment (e.g., Cinnamon, GNOME, KDE)
   - Architecture (amd64)
3. **Describe the problem** clearly with steps to reproduce
4. **Include logs** if the app crashes (look in `~/.config/minimax-agent/logs/`)

### Testing

The most valuable contribution is testing on different distributions:

| Distribution | Version | Desktop | Status |
|-------------|---------|---------|--------|
| Linux Mint  | 21.x    | Cinnamon| Tested |
| Ubuntu      | 22.04+  | GNOME   | Likely works |
| Debian      | 11+     | Various | Likely works |
| Fedora      | 38+     | GNOME   | Needs testing |
| RHEL        | 9+      | GNOME   | Needs testing |
| openSUSE    | Tumbleweed | KDE  | Needs testing |
Please report any test results by opening an issue!

### Documentation

Improvements to documentation are always welcome:
- Installation guides for specific distributions
- Troubleshooting guides
- Tips and tricks

### Code Contributions

For build script improvements:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Distribution-Specific Notes

### Linux Mint
Primary tested distribution. Should work out of the box.

### Ubuntu/Debian
Dependencies should install automatically. If not, install these:
```bash
sudo apt install libgtk-3-0 libnss3 libasound2
```

### Fedora/RHEL/openSUSE

Native RPM packages are now supported. Use the RPM build script instead of converting the `.deb` with `alien`.

**Fedora/RHEL:**
```bash
sudo dnf install rpm-build rpmdevtools desktop-file-utils tar gzip
./build-rpm.sh
tests/verify-rpm.sh output/minimax-agent-3.0.13-1.*.x86_64.rpm
```

**openSUSE:**
```bash
sudo zypper install rpm-build desktop-file-utils tar gzip
./build-rpm.sh
tests/verify-rpm.sh output/minimax-agent-3.0.13-1.*.x86_64.rpm
```

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others who are new to Linux

## Questions?

Open an issue on GitHub for any questions about contributing.
