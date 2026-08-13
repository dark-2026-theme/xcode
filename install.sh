#!/usr/bin/env bash
#
# dark-2026 -- Xcode installer
#
# Copies dark-2026.xccolorscheme into Xcode's theme directory as
# dark-2026.xccolortheme, which is the extension Xcode looks for.
#
#   ./install.sh              install (backs up any existing copy)
#   ./install.sh --uninstall  remove the installed theme
#   ./install.sh --help       usage

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/dark-2026.xccolorscheme"
THEME_DIR="${XCODE_THEME_DIR:-$HOME/Library/Developer/Xcode/UserData/FontAndColorThemes}"
TARGET="$THEME_DIR/dark-2026.xccolortheme"

bold=''; dim=''; red=''; green=''; yellow=''; reset=''
if [ -t 1 ]; then
  bold=$'\033[1m'; dim=$'\033[2m'; red=$'\033[31m'
  green=$'\033[32m'; yellow=$'\033[33m'; reset=$'\033[0m'
fi

info()  { printf '%s\n' "$*"; }
ok()    { printf '%s✓%s %s\n' "$green" "$reset" "$*"; }
warn()  { printf '%s!%s %s\n' "$yellow" "$reset" "$*" >&2; }
die()   { printf '%s✗%s %s\n' "$red" "$reset" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
${bold}dark-2026 -- Xcode installer${reset}

Usage: install.sh [options]

Options:
  -u, --uninstall   Remove the installed theme (and nothing else)
  -f, --force       Overwrite an existing theme without keeping a backup
  -h, --help        Show this message

Environment:
  XCODE_THEME_DIR   Install location
                    ${dim}(default: ~/Library/Developer/Xcode/UserData/FontAndColorThemes)${reset}
EOF
}

action='install'
force=0

while [ $# -gt 0 ]; do
  case "$1" in
    -u|--uninstall) action='uninstall' ;;
    -f|--force)     force=1 ;;
    -h|--help)      usage; exit 0 ;;
    *)              usage >&2; die "unknown option: $1" ;;
  esac
  shift
done

if [ "$(uname -s)" != 'Darwin' ]; then
  die "Xcode themes only make sense on macOS (found $(uname -s))."
fi

if [ "$action" = 'uninstall' ]; then
  if [ -e "$TARGET" ]; then
    rm -f "$TARGET"
    ok "Removed $TARGET"
    info "Pick another theme in Xcode ▸ Settings ▸ Themes."
  else
    info "Nothing to do -- $TARGET is not installed."
  fi
  exit 0
fi

[ -f "$SOURCE" ] || die "theme file not found: $SOURCE"

if command -v plutil >/dev/null 2>&1; then
  plutil -lint "$SOURCE" >/dev/null 2>&1 || die "$SOURCE is not a valid property list."
fi

mkdir -p "$THEME_DIR"

if [ -e "$TARGET" ]; then
  if [ "$force" -eq 1 ]; then
    rm -f "$TARGET"
  else
    backup="$TARGET.$(date +%Y%m%d%H%M%S).bak"
    mv "$TARGET" "$backup"
    warn "Existing theme moved to $(basename "$backup")"
  fi
fi

cp "$SOURCE" "$TARGET"
ok "Installed $TARGET"

if pgrep -xq Xcode 2>/dev/null; then
  warn "Xcode is running -- restart it before the theme shows up in the list."
fi

cat <<EOF

Next: ${bold}Xcode ▸ Settings ▸ Themes${reset} and pick ${bold}dark-2026${reset}.
${dim}The theme sets SF Mono 12; change the font in that panel to taste.${reset}
EOF
