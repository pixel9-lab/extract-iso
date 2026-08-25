#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${HOME}/.local/bin"
APPS="${HOME}/.local/share/applications"
SVC="${HOME}/.local/share/kio/servicemenus"

mkdir -p "$BIN" "$APPS" "$SVC"
install -Dm755 "$ROOT/extract-iso.sh" "$BIN/extract-iso.sh"

cat > "$APPS/extract-iso.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Extract ISO
GenericName=ISO Extractor
Comment=Extract an ISO image into ./ext in the chosen directory
TryExec=$BIN/extract-iso.sh
Exec=$BIN/extract-iso.sh --desktop %f
Icon=media-optical
Terminal=false
Categories=Utility;Archiving;
MimeType=application/vnd.efi.iso;application/x-iso9660-image;application/x-cd-image;application/x-iso;
Keywords=iso;extract;7z;archive;
StartupNotify=false
EOF

cat > "$SVC/extract-iso.desktop" <<EOF
[Desktop Entry]
Type=Service
X-KDE-ServiceTypes=KonqPopupMenu/Plugin
MimeType=application/vnd.efi.iso;application/x-iso9660-image;application/x-cd-image;application/x-iso;
Actions=extractISO;
X-KDE-Priority=TopLevel
X-KDE-MaxNumberOfUrls=1

[Desktop Action extractISO]
Name=Extract ISO
Icon=media-optical
TryExec=$BIN/extract-iso.sh
Exec=$BIN/extract-iso.sh --desktop %f
EOF

cp "$APPS/extract-iso.desktop" "$ROOT/extract-iso.desktop"
rm -f "$BIN/extract-iso-gui.sh" "$BIN/extract-iso-launch.sh" "$BIN/extract-iso-progress.sh"

command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APPS" 2>/dev/null || true
command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 --noincremental 2>/dev/null || true

echo "Installed:"
echo "  $BIN/extract-iso.sh"
echo "  $APPS/extract-iso.desktop"
echo "  $SVC/extract-iso.desktop"
echo
echo "Deps: bash, 7z, zenity, wezterm (or konsole)"
echo "CLI:  extract-iso.sh image.iso"
echo "GUI:  extract-iso.sh --gui [image.iso]"
echo "Menu: search for Extract ISO"
