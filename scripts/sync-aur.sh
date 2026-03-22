#!/usr/bin/env bash
# Generate AUR package files from upstream PKGBUILD + our patches
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AUR_DIR="$ROOT/aur"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

ARCH_PKG="https://gitlab.archlinux.org/archlinux/packaging/packages/systemd.git"

echo ":: Fetching official PKGBUILD"
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
cat "$ROOT/pkgbuild.append" >> "$AUR_DIR/PKGBUILD"

# Copy patch files needed by the PKGBUILD
cp "$ROOT/patches/"*.patch "$AUR_DIR/"

# Generate .SRCINFO
cd "$AUR_DIR"
makepkg --printsrcinfo > .SRCINFO

VER=$(grep -m1 'pkgver=' PKGBUILD | cut -d= -f2)
echo ":: AUR package ready for systemd $VER"
echo ":: Review, then: cd aur && git add -A && git commit && git push"
