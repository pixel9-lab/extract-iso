# extract-iso

One Bash script to extract ISO images with `7z` into an `./ext` folder — plus a desktop entry for your app menu / file manager.

## Features

- CLI extractor with colored progress (`7z -bsp1`)
- Optional GUI via zenity (pick ISO + output directory)
- Progress in WezTerm (falls back to Konsole)
- App menu entry and KDE Dolphin right-click (via install script)

## Requirements

- Linux (tested on openSUSE Tumbleweed / KDE Plasma)
- `bash`
- `7z` — openSUSE: `sudo zypper install 7zip`
- `zenity` — for GUI / desktop use
- `wezterm` (recommended) or `konsole` — for progress window

## Install

```bash
cd ~/Downloads/extract-iso
chmod +x install.sh extract-iso.sh
./install.sh
```

Installs:

- `~/.local/bin/extract-iso.sh`
- `~/.local/share/applications/extract-iso.desktop`
- `~/.local/share/kio/servicemenus/extract-iso.desktop` (KDE)

Ensure `~/.local/bin` is on your `PATH`.

## Usage

### CLI

```bash
extract-iso.sh /path/to/image.iso
```

### GUI

```bash
extract-iso.sh --gui
extract-iso.sh --gui /path/to/image.iso
```

### App menu / Dolphin

Search for **Extract ISO**, or right-click an ISO → **Extract ISO**.

## Project files

| File | Purpose |
|------|---------|
| `extract-iso.sh` | The whole tool (CLI + GUI + desktop entrypoint) |
| `extract-iso.desktop` | App menu template |
| `install.sh` | Installer |
| `LICENSE` | MIT |

## Uninstall

```bash
rm -f ~/.local/bin/extract-iso.sh       ~/.local/share/applications/extract-iso.desktop       ~/.local/share/kio/servicemenus/extract-iso.desktop
```

## License

MIT
