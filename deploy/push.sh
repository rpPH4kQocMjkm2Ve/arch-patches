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
rm -f "$REPODIR"/systemd-*.pkg.tar.zst
cp -v "${PKGS[@]}" "$REPODIR/"
repo-add -R "$REPODIR/$REPONAME.db.tar.gz" "$REPODIR"/*.pkg.tar.zst

echo "==> Repository updated: $REPODIR"
echo "==> Run: sudo pacman -Syu"
