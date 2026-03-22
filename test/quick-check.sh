#!/usr/bin/env bash
set -euo pipefail

BUILDDIR="${1:-.build}"

PKG=$(find "$BUILDDIR" -maxdepth 1 -name 'systemd-[0-9]*.pkg.tar.zst' | head -1)
if [[ -z "$PKG" ]]; then
    echo "ERROR: no systemd package found in $BUILDDIR" >&2
    exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
bsdtar -xf "$PKG" -C "$TMP"

echo "==> Checking for age-verification remnants"
fail=0

# Check shared library
SO=$(find "$TMP" -name 'libsystemd-shared-*.so' | head -1)
if [[ -n "$SO" ]]; then
    if strings "$SO" | grep -qi 'birthDate'; then
        echo "  FAIL: birthDate in $(basename "$SO")"
        fail=1
    else
        echo "  OK: $(basename "$SO")"
    fi

    if strings "$SO" | grep -qi 'birth_date'; then
        echo "  FAIL: birth_date in $(basename "$SO")"
        fail=1
    else
        echo "  OK: no birth_date symbol"
    fi
fi

# Check homectl
if [[ -f "$TMP/usr/bin/homectl" ]]; then
    if strings "$TMP/usr/bin/homectl" | grep -qi 'birth-date'; then
        echo "  FAIL: --birth-date in homectl"
        fail=1
    else
        echo "  OK: homectl"
    fi
fi

if (( fail )); then
    echo "==> FAILED"
    exit 1
fi

echo "==> All checks passed"
