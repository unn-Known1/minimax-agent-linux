# Contributing to MiniMax Agent Linux

Thank you for your interest in contributing to the MiniMax Agent Linux port!

## How to Contribute

### Reporting Issues

1. **Check existing issues** - Before creating a new issue, please search to see if it's already reported
2. **Include system information**:
   - Distribution and version (e.g., Linux Mint 21.2, Cachy OS 24.04)
   - Desktop environment (e.g., Cinnamon, GNOME, KDE, Hyprland)
   - Architecture (amd64)
   - For Arch-based: `pacman -Qi minimax-agent` output is helpful
3. **Describe the problem** clearly with steps to reproduce
4. **Include logs** if the app crashes (look in `~/.config/minimax-agent/logs/` and `~/.mavis/logs/`)

### Testing

The most valuable contribution is testing on different distributions:

| Distribution  | Version | Desktop    | Status |
|---------------|---------|------------|--------|
| Linux Mint    | 21.x    | Cinnamon   | Tested |
| Ubuntu        | 22.04+  | GNOME      | Tested |
| Debian        | 11+     | Various    | Tested |
| **Cachy OS**  | **any** | **KDE / Hyprland / GNOME** | **Needs testing — first-class target** |
| Arch          | rolling | Any        | Needs testing |
| Manjaro       | stable  | KDE / GNOME| Needs testing |
| EndeavourOS   | any     | Any        | Needs testing |

**If you have a Cachy OS machine**, the project would especially benefit from your testing. Things worth checking:

- Does the package install cleanly with `pacman -U`?
- Does the AUR helper workflow (`paru -S minimax-agent`, after AUR publication) work?
- Does the `install` hook correctly create `~/.mavis/{logs,screenshots}` for your user?
- Does the backend daemon (`systemctl --user status mavis.service`) start after login?
- Does x86-64-v3 optimization work? (Check that `npm rebuild` in the daemon dir doesn't fail.)
- Does the Google OAuth flow complete (the `minimax://` protocol handler registration)?

Please report any test results by opening an issue with the output of:

```bash
# On Cachy OS:
pacman -Qi minimax-agent
systemctl --user status mavis.service
cat /etc/os-release
```

### Documentation

Improvements to documentation are always welcome:
- Installation guides for specific distributions
- Troubleshooting guides
- Tips and tricks
- Translations

### Code Contributions

For build script improvements:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

For changes to the Cachy OS / Arch packaging, see `AGENTS.md` for the release flow and how to regenerate `.SRCINFO`.

## Distribution-Specific Notes

### Linux Mint
Primary tested distribution. Should work out of the box.

### Ubuntu / Debian
Dependencies should install automatically. If not, install these:
```bash
sudo apt install libgtk-3-0 libnss3 libasound2
```

### Cachy OS
- Package format: `.pkg.tar.zst`
- Install: `sudo pacman -U minimax-agent-<version>-1-x86_64.pkg.tar.zst`
- Source of truth: `cachyos/PKGBUILD`
- Install hook: `cachyos/minimax-agent.install`
- Build script: `build-cachyos.sh`
- For AUR submission, see the "AUR submission" section of `AGENTS.md`

When reporting issues on Cachy OS, please include:
```bash
pacman -Qi minimax-agent
journalctl --user -u mavis.service --no-pager -n 50
cat /etc/cachyos-release 2>/dev/null || cat /etc/os-release | head -5
```

### Arch / Manjaro / EndeavourOS
Same package as Cachy OS (`minimax-agent-<version>-1-x86_64.pkg.tar.zst`). The install hook detects these distros and behaves the same way (only the Cachy OS-specific hint is suppressed).

### Fedora / RHEL
This package is .deb based. For RPM-based systems, you would need to convert it using `alien`:
```bash
sudo dnf install alien
sudo alien -r minimax-agent_3.0.68_amd64.deb
```

A proper `.spec` file for Fedora would be a great contribution — open a PR.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others who are new to Linux

## Questions?

Open an issue on GitHub for any questions about contributing.
