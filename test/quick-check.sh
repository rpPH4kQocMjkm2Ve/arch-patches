#!/usr/bin/env bash
set -euo pipefail

BUILDDIR="${1:-.build}"

# Check both the main systemd package and systemd-libs,
# since libsystemd-shared lives in the main package but
# systemd-libs is the most widely depended-upon.
MAIN_PKG=$(find "$BUILDDIR" -maxdepth 1 -name 'systemd-[0-9]*.pkg.tar.zst' | head -1)
LIBS_PKG=$(find "$BUILDDIR" -maxdepth 1 -name 'systemd-libs-[0-9]*.pkg.tar.zst' | head -1)

if [[ -z "$MAIN_PKG" ]]; then
    echo "ERROR: no systemd package found in $BUILDDIR" >&2
    exit 1
fi

fail=0

check_pkg() {
    local pkg="$1"
    local label="$2"
    local tmp
    tmp=$(mktemp -d)
    # shellcheck disable=SC2064
    trap "rm -rf '$tmp'" RETURN

    bsdtar -xf "$pkg" -C "$tmp"

    echo "==> Checking $label ($(basename "$pkg"))"

    # Shared library
    local so
    so=$(find "$tmp" -name 'libsystemd-shared-*.so' | head -1)
    if [[ -n "$so" ]]; then
        if strings "$so" | grep -qi 'birthDate'; then
            echo "  FAIL: birthDate string in $(basename "$so")"
            fail=1
        else
            echo "  OK: $(basename "$so") — no birthDate"
        fi

        if strings "$so" | grep -qi 'birth_date'; then
            echo "  FAIL: birth_date symbol in $(basename "$so")"
            fail=1
        else
            echo "  OK: $(basename "$so") — no birth_date"
        fi
    fi

    # homectl binary
    if [[ -f "$tmp/usr/bin/homectl" ]]; then
        if strings "$tmp/usr/bin/homectl" | grep -qi 'birth-date'; then
            echo "  FAIL: --birth-date in homectl"
            fail=1
        else
            echo "  OK: homectl — no birth-date"
        fi
    fi

    # libsystemd.so (public library in systemd-libs)
    local libsd
    libsd=$(find "$tmp" -name 'libsystemd.so*' -not -type l | head -1)
    if [[ -n "$libsd" ]]; then
        if strings "$libsd" | grep -qi 'birthDate'; then
            echo "  FAIL: birthDate in $(basename "$libsd")"
            fail=1
        else
            echo "  OK: $(basename "$libsd") — no birthDate"
        fi
    fi
}

check_pkg "$MAIN_PKG" "systemd (main)"

if [[ -n "$LIBS_PKG" ]]; then
    check_pkg "$LIBS_PKG" "systemd-libs"
else
    echo "WARN: systemd-libs package not found, skipping" >&2
fi

if (( fail )); then
    echo "==> FAILED"
    exit 1
fi

echo "==> All checks passed"
