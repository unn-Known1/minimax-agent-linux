# Installation Guide

This guide explains how to install the MiniMax Agent for Linux.

## Prerequisites

Before installing, ensure you have the required dependencies:

```bash
sudo apt update
sudo apt install wget curl unzip libgtk-3-0 libnss3 libasound2 libxss1 libgbm1 nodejs npm
```

## Full Installation Steps

### Step 1: Install the .deb Package

```bash
sudo dpkg -i minimax-agent_3.0.68_amd64.deb
sudo apt --fix-broken install
```

### Step 2: Download and Setup Electron Runtime

```bash
sudo ./setup.sh
```

### Step 3: Install Daemon Dependencies

If setup.sh didn't run npm install automatically:

```bash
cd /opt/minimax-agent/resources/resources/daemon
sudo npm install --omit=dev
```

### Step 4: (Optional) Install OpenCode

Place the Linux `opencode` binary at:
```
/opt/minimax-agent/resources/resources/opencode/opencode
```

### Step 5: Launch

You can launch MiniMax Agent from:
- Application menu
- Terminal: `minimax-agent`

## File Locations

After installation:
- Application binary: `/opt/minimax-agent/electron`
- App code: `/opt/minimax-agent/resources/app.asar`
- Daemon: `/opt/minimax-agent/resources/resources/daemon/`
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

If missing, re-run setup.sh.

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
