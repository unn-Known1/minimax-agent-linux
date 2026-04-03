# Installation Guide

This guide explains how to install the MiniMax Agent for Linux.

## Prerequisites

Before installing, ensure you have the required dependencies:

```bash
sudo apt update
sudo apt install wget curl unzip libgtk-3-0 libnss3 libasound2 libxss1 libgbm1
```

## Full Installation Steps

### Step 1: Download the Package

Download the latest `.deb` package from the [Releases](https://github.com/unn-Known1/minimax-agent-linux/releases) page.

### Step 2: Download Binary Assets

Due to GitHub's file size limits, the binary files (Electron runtime) are hosted separately.

Download the binary package:
```bash
wget https://github.com/unn-Known1/minimax-agent-linux/releases/download/v3.0.13/electron-runtime.tar.gz
```

Extract to `/opt/`:
```bash
sudo tar -xzf electron-runtime.tar.gz -C /opt/
```

### Step 3: Install the .deb Package

```bash
sudo dpkg -i minimax-agent_3.0.13_amd64.deb
```

### Step 4: Fix Dependencies (if needed)

If you see dependency errors:
```bash
sudo apt --fix-broken install
```

### Step 5: Launch

You can launch MiniMax Agent from:
- Application menu
- Terminal: `minimax-agent`
- Or by clicking the desktop icon (if created)

## File Locations

After installation:
- Application binary: `/opt/minimax-agent/electron`
- Resources: `/opt/minimax-agent/resources/`
- Desktop file: `/usr/share/applications/minimax-agent.desktop`
- Launcher: `/usr/bin/minimax-agent`

## Troubleshooting

### "Command not found" after installation

Log out and log back in, or run:
```bash
hash -r
```

### App doesn't start

Check if Electron is present:
```bash
ls -la /opt/minimax-agent/electron
```

If missing, re-run the binary download step.

### Google login fails

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

## Uninstallation

```bash
sudo dpkg -r minimax-agent
sudo rm -rf /opt/minimax-agent
sudo rm -rf /var/cache/minimax-agent
```
