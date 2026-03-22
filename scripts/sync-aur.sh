#!/usr/bin/env bash
# Generate AUR package files from upstream PKGBUILD + our patches
#
# Usage: sync-aur.sh <package-name>
#   e.g. sync-aur.sh systemd
#        sync-aur.sh xdg-desktop-portal
set -euo pipefail

PKGNAME="${1:?Usage: sync-aur.sh <package-name>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG_DIR="$ROOT/packages/$PKGNAME"

if [[ ! -d "$PKG_DIR" ]]; then
    echo "ERROR: package directory not found: $PKG_DIR" >&2
    exit 1
fi

if [[ ! -f "$PKG_DIR/pkgbuild.append" ]]; then
    echo "ERROR: no pkgbuild.append in $PKG_DIR" >&2
    exit 1
fi

ARCH_PKG="https://gitlab.archlinux.org/archlinux/packaging/packages/${PKGNAME}.git"
AUR_DIR="$PKG_DIR/aur"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo ":: Fetching official PKGBUILD for $PKGNAME"
git clone --depth 1 "$ARCH_PKG" "$TMP/upstream"

echo ":: Generating AUR PKGBUILD"
mkdir -p "$AUR_DIR"

# Copy all upstream files (install scripts, hooks, configs, etc.)
find "$TMP/upstream" -maxdepth 1 -type f ! -name '.git*' \
    -exec cp {} "$AUR_DIR/" \;

# Replace maintainer, credit the original as contributor
sed -i '1,/^$/{
  s|^# Maintainer:.*|# Maintainer:  fa5e4658010be730 \n# Contributor: Christian Hesse <mail@eworm.de>|
}' "$AUR_DIR/PKGBUILD"

# Append our modifications
cat "$PKG_DIR/pkgbuild.append" >> "$AUR_DIR/PKGBUILD"

# Copy patch files needed by the PKGBUILD
if compgen -G "$PKG_DIR/patches/"*.patch > /dev/null; then
    cp "$PKG_DIR/patches/"*.patch "$AUR_DIR/"
fi

# Generate .SRCINFO
cd "$AUR_DIR"
makepkg --printsrcinfo > .SRCINFO

VER=$(grep -m1 'pkgver=' PKGBUILD | cut -d= -f2)
echo ":: AUR package ready for $PKGNAME $VER"
echo ":: Review, then: cd packages/$PKGNAME/aur && git add -A && git commit && git push"
