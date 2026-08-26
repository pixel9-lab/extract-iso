#!/usr/bin/env bash
# extract-iso — extract ISO images with 7z
set -Eeuo pipefail
SELF="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
usage() { cat <<EOF
Usage:
  extract-iso.sh <file.iso>
  extract-iso.sh --gui [file.iso]
Extracts the ISO into ./ext (CLI) or ./ext inside a chosen directory (GUI).
EOF
}
die() { printf "%s
" "${RED:-}Error:${RESET:-} $*" >&2; exit 1; }
on_error() { local ec=$?; printf "
%s
" "${RED:-}Extraction failed.${RESET:-}" >&2; exit "$ec"; }
init_colors() {
  if [[ -t 1 && -z "${NO_COLOR:-}" ]] && command -v tput >/dev/null 2>&1; then
    BOLD=$(tput bold 2>/dev/null || true); RESET=$(tput sgr0 2>/dev/null || true)
    RED=$(tput setaf 1 2>/dev/null || true); GREEN=$(tput setaf 2 2>/dev/null || true)
    YELLOW=$(tput setaf 3 2>/dev/null || true); BLUE=$(tput setaf 4 2>/dev/null || true)
    MAGENTA=$(tput setaf 5 2>/dev/null || true); CYAN=$(tput setaf 6 2>/dev/null || true)
  else BOLD= RESET= RED= GREEN= YELLOW= BLUE= MAGENTA= CYAN=; fi
}
banner() {
  printf "%s
" "${BOLD}${CYAN}========================================${RESET}"
  printf "%s
" "${BOLD}${CYAN}            ISO Extractor               ${RESET}"
  printf "%s
" "${BOLD}${CYAN}========================================${RESET}"
}
info() { printf "%s %s
" "${BLUE}[*]${RESET}" "$*"; }
success() { printf "%s %s
" "${GREEN}[+]${RESET}" "$*"; }
warn() { printf "%s %s
" "${YELLOW}[!]${RESET}" "$*" >&2; }
normalize_path() {
  local p=$1
  if [[ "$p" == file://* ]]; then
    if command -v python3 >/dev/null 2>&1; then
      p=$(python3 -c "import sys,urllib.parse; print(urllib.parse.unquote(sys.argv[1].removeprefix("file://")))" "$p")
    else p=${p#file://}; p=${p//%20/ }; fi
  fi
  printf "%s
" "$p"
}
do_extract() {
  local iso=$1 dest=./ext
  [[ -f "$iso" ]] || die "ISO not found: $iso"
  case "${iso,,}" in *.iso) ;; *) warn "File does not end with .iso, attempting extraction anyway." ;; esac
  command -v 7z >/dev/null 2>&1 || die "7z is not installed. On openSUSE: sudo zypper install 7zip"
  mkdir -p "$dest"
  banner
  info "Source      : $iso"
  info "Destination : $(realpath "$dest")"
  info "Mode        : overwrite existing files"
  printf "
%s
" "${MAGENTA}Progress:${RESET}"
  7z x -y -aoa -bsp1 "$iso" "-o$dest"
  printf "
"; success "Done."; success "Extracted to: $(realpath "$dest")"
}
do_progress() {
  local iso=$1 dir=$2 status_file=${3:-}
  cd "$dir"; set +e; do_extract "$iso"; local ec=$?; set -e
  [[ -n "$status_file" ]] && printf "%s
" "$ec" >"$status_file"
  printf "
"
  if [[ -t 0 && -t 1 ]]; then read -n1 -s -r -p "Press any key to close..."; printf "
"; fi
  exit "$ec"
}
zenity_quiet() {
  local out err status; err=$(mktemp); set +e; out=$(zenity "$@" 2>"$err"); status=$?; set -e
  [[ -s "$err" ]] && grep -Ev "Adwaita-WARNING|gtk-application-prefer-dark-theme|AdwStyleManager" "$err" >&2 || true
  rm -f "$err"; [[ -n "$out" ]] && printf "%s
" "$out"; return "$status"
}
run_in_terminal() {
  local iso=$1 dir=$2 status_file=$3
  if command -v wezterm >/dev/null 2>&1; then
    wezterm start --always-new-process -- "$SELF" --progress "$iso" "$dir" "$status_file"; return $?
  fi
  if command -v konsole >/dev/null 2>&1; then
    konsole --nofork -e "$SELF" --progress "$iso" "$dir" "$status_file"; return $?
  fi
  ( cd "$dir" && do_extract "$iso" ); local ec=$?; printf "%s
" "$ec" >"$status_file"; return "$ec"
}
do_gui() {
  local iso=${1:-} status_file=""
  cleanup() { [[ -n "${status_file:-}" && -f "$status_file" ]] && rm -f "$status_file" || true; }
  trap cleanup EXIT
  command -v zenity >/dev/null 2>&1 || die "zenity is required for the GUI. On openSUSE: sudo zypper install zenity"
  [[ -n "$iso" ]] && iso=$(normalize_path "$iso")
  if [[ -z "$iso" ]]; then
    iso=$(zenity_quiet --file-selection --title="Select ISO to extract" --file-filter="ISO images | *.iso *.ISO" --file-filter="All files | *" || true)
  fi
  [[ -n "${iso:-}" ]] || exit 0
  if [[ ! -f "$iso" ]]; then zenity_quiet --error --title="Extract ISO" --text="ISO not found:

$iso" || true; exit 1; fi
  local iso_dir dir; iso_dir=$(dirname -- "$iso")
  dir=$(zenity_quiet --file-selection --directory --filename="$iso_dir/" --title="Select output parent directory (creates ./ext inside it)" || true)
  [[ -n "${dir:-}" ]] || exit 0
  status_file=$(mktemp); echo 1 >"$status_file"
  set +e; run_in_terminal "$iso" "$dir" "$status_file"; local term_status=$?; set -e
  local status=$term_status
  if [[ -f "$status_file" ]]; then status=$(tr -cd "0-9" <"$status_file" || true); [[ -n "$status" ]] || status=$term_status; fi
  if [[ "$status" -eq 0 ]]; then
    zenity_quiet --info --title="Extract ISO" --text="Extraction complete.

Output: $dir/ext" || true
  else
    zenity_quiet --error --title="Extract ISO" --text="Extraction failed (exit $status)." || true
  fi
  exit "$status"
}
do_desktop() {
  local log="${XDG_CACHE_HOME:-$HOME/.cache}/extract-iso-launch.log"
  mkdir -p "$(dirname "$log")"
  { echo "===== $(date -Iseconds) ====="; echo "argv: $*"; echo "DISPLAY=${DISPLAY:-} WAYLAND=${WAYLAND_DISPLAY:-}"; } >>"$log" 2>&1
  export DISPLAY="${DISPLAY:-:0}"; export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  if command -v setsid >/dev/null 2>&1; then setsid -f "$SELF" --gui "$@" >>"$log" 2>&1
  else nohup "$SELF" --gui "$@" >>"$log" 2>&1 & fi
  exit 0
}
trap on_error ERR; init_colors
mode=cli
if [[ $# -ge 1 ]]; then
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --gui) shift; mode=gui ;;
    --desktop) shift; mode=desktop ;;
    --progress) shift; [[ $# -ge 2 ]] || die "--progress requires <iso> <dir> [status_file]"; do_progress "$1" "$2" "${3:-}" ;;
    -*) usage >&2; exit 1 ;;
  esac
fi
case "$mode" in
  desktop) do_desktop "$@" ;;
  gui) do_gui "${1:-}" ;;
  cli) [[ $# -eq 1 ]] || { usage >&2; exit 1; }; do_extract "$1" ;;
esac
