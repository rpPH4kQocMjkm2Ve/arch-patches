#!/usr/bin/env bash
set -euo pipefail

BUILDDIR="${1:-.build}"

PKG=$(find "$BUILDDIR" -maxdepth 1 -name 'xdg-desktop-portal-[0-9]*.pkg.tar.zst' | head -1)
if [[ -z "$PKG" ]]; then
    echo "ERROR: no xdg-desktop-portal package found in $BUILDDIR" >&2
    exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
bsdtar -xf "$PKG" -C "$TMP"

echo "==> Checking for ParentalControls remnants"
fail=0

# Check main binary
BINARY=$(find "$TMP" -name 'xdg-desktop-portal' -type f | head -1)
if [[ -n "$BINARY" ]]; then
    if strings "$BINARY" | grep -qi 'ParentalControls'; then
        echo "  FAIL: ParentalControls in $(basename "$BINARY")"
        fail=1
    else
        echo "  OK: $(basename "$BINARY") — no ParentalControls"
    fi
fi

# Check D-Bus interface files
if find "$TMP" -name '*ParentalControls*' | grep -q .; then
    echo "  FAIL: ParentalControls interface file found"
    fail=1
else
    echo "  OK: no ParentalControls interface files"
fi

if (( fail )); then
    echo "==> FAILED"
    exit 1
fi

echo "==> All checks passed"
