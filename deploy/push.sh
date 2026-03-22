#!/usr/bin/env bash
set -euo pipefail

BUILDDIR="${1:-.build}"
REPODIR="${2:-/var/cache/pacman/custom}"
REPONAME="${3:-custom}"

PKGS=("$BUILDDIR"/*.pkg.tar.zst)
if (( ${#PKGS[@]} == 0 )); then
    echo "ERROR: no packages in $BUILDDIR" >&2
    exit 1
fi

mkdir -p "$REPODIR"

# Remove old systemd packages before copying new ones
rm -f "$REPODIR"/systemd-*.pkg.tar.zst

# Copy built packages and track their destination paths
DEST_PKGS=()
for pkg in "${PKGS[@]}"; do
    cp -v "$pkg" "$REPODIR/"
    DEST_PKGS+=("$REPODIR/$(basename "$pkg")")
done

# Only add the packages we just copied — avoid re-indexing
# unrelated packages that may live in the same repo directory
repo-add -R "$REPODIR/$REPONAME.db.tar.gz" "${DEST_PKGS[@]}"

echo "==> Repository updated: $REPODIR"
echo "==> Run: sudo pacman -Syu"
