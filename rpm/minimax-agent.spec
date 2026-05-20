%global appdir /opt/%{name}

Name:           minimax-agent
Version:        3.0.13
Release:        1%{?dist}
Summary:        MiniMax Agent Desktop Application
License:        LicenseRef-Proprietary
URL:            https://github.com/unn-Known1/minimax-agent-linux
Source0:        %{name}-%{version}.tar.gz

ExclusiveArch:  x86_64

BuildRequires:  desktop-file-utils

Requires:       xdg-utils

%if 0%{?suse_version}
Requires:       glibc
Requires:       mozilla-nss
Requires:       libX11-6
Requires:       libX11-xcb1
Requires:       libxcb1
Requires:       libXcomposite1
Requires:       libXdamage1
Requires:       libXext6
Requires:       libXfixes3
Requires:       libXrandr2
Requires:       libXrender1
Requires:       libXss1
Requires:       libXtst6
Requires:       libglib-2_0-0
Requires:       gtk3
Requires:       libnotify4
Requires:       mozilla-nspr
Requires:       libdbus-1-3
Requires:       libdrm2
Requires:       libgbm1
Requires:       alsa-lib
%else
Requires:       glibc
Requires:       nss
Requires:       libX11
Requires:       libX11-xcb
Requires:       libxcb
Requires:       libXcomposite
Requires:       libXdamage
Requires:       libXext
Requires:       libXfixes
Requires:       libXrandr
Requires:       libXrender
Requires:       libXScrnSaver
Requires:       libXtst
Requires:       glib2
Requires:       gtk3
Requires:       libnotify
Requires:       nspr
Requires:       dbus-libs
Requires:       libdrm
Requires:       mesa-libgbm
Requires:       alsa-lib
%endif

%description
MiniMax Agent desktop application for Linux.

This package installs the MiniMax Agent launcher, desktop integration,
custom protocol handlers, and application payload under /opt/minimax-agent.

%prep
%autosetup -n %{name}-%{version}

%build
# No compilation. This project repackages prebuilt Electron assets.

%install
rm -rf %{buildroot}

if [ ! -d linux-build/usr ]; then
    echo "Missing linux-build/usr payload"
    exit 1
fi

if [ ! -d linux-build/opt/minimax-agent ]; then
    echo "Missing linux-build/opt/minimax-agent payload"
    echo "Stage Electron/runtime assets before building the RPM."
    exit 1
fi

cp -a linux-build/usr %{buildroot}/
cp -a linux-build/opt %{buildroot}/

chmod 0755 %{buildroot}%{_bindir}/minimax-agent

desktop-file-validate %{buildroot}%{_datadir}/applications/minimax-agent.desktop

%post
if [ -x /usr/bin/update-desktop-database ]; then
    /usr/bin/update-desktop-database %{_datadir}/applications >/dev/null 2>&1 || :
fi

if [ -x /usr/bin/gtk-update-icon-cache ]; then
    /usr/bin/gtk-update-icon-cache -q -t -f %{_datadir}/icons/hicolor >/dev/null 2>&1 || :
fi

if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default minimax-agent.desktop x-scheme-handler/minimax >/dev/null 2>&1 || :
    xdg-mime default minimax-agent.desktop x-scheme-handler/minimax-agent >/dev/null 2>&1 || :
fi

if command -v gio >/dev/null 2>&1; then
    gio mime x-scheme-handler/minimax minimax-agent.desktop >/dev/null 2>&1 || :
    gio mime x-scheme-handler/minimax-agent minimax-agent.desktop >/dev/null 2>&1 || :
fi

if [ -f %{appdir}/chrome-sandbox ]; then
    if command -v unshare >/dev/null 2>&1 && [ -L /proc/self/ns/user ] && unshare --user true >/dev/null 2>&1; then
        chmod 0755 %{appdir}/chrome-sandbox >/dev/null 2>&1 || :
    else
        chown root:root %{appdir}/chrome-sandbox >/dev/null 2>&1 || :
        chmod 4755 %{appdir}/chrome-sandbox >/dev/null 2>&1 || :
    fi
fi

%postun
if [ -x /usr/bin/update-desktop-database ]; then
    /usr/bin/update-desktop-database %{_datadir}/applications >/dev/null 2>&1 || :
fi

if [ -x /usr/bin/gtk-update-icon-cache ]; then
    /usr/bin/gtk-update-icon-cache -q -t -f %{_datadir}/icons/hicolor >/dev/null 2>&1 || :
fi

%files
%{_bindir}/minimax-agent
%{_datadir}/applications/minimax-agent.desktop
%{_datadir}/icons/hicolor/*/apps/minimax-agent.*
%{appdir}

%changelog
* Wed May 20 2026 MiniMax <noreply@example.com> - 3.0.13-1
- Add native RPM packaging support
