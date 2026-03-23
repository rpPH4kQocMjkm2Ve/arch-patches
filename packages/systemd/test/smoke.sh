#!/usr/bin/env bash
# Smoke test: install patched packages in an nspawn container and verify
set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: smoke test requires root" >&2
    exit 1
fi

BUILDDIR="${1:-.build}"

PKGS=("$BUILDDIR"/*.pkg.tar.zst)
if (( ${#PKGS[@]} == 0 )); then
    echo "ERROR: no packages in $BUILDDIR" >&2
    exit 1
fi

ROOT=$(mktemp -d /tmp/sd-smoke.XXXXXX)
[[ -z "$ROOT" || "$ROOT" == "/" ]] && { echo "ERROR: bad ROOT=$ROOT" >&2; exit 1; }
[[ "$ROOT" != /tmp/sd-smoke.* ]] && { echo "ERROR: ROOT outside tmpdir: $ROOT" >&2; exit 1; }
chmod 755 "$ROOT"
chown root:root "$ROOT"
trap 'rm -rf "$ROOT"' EXIT

echo "==> Creating test root"
pacstrap -cGM "$ROOT" base

echo "==> Installing patched packages"
pacman -U --root "$ROOT" --dbpath "$ROOT/var/lib/pacman" \
    --noconfirm --overwrite='*' "${PKGS[@]}"

# bash as PID 1 — prevents systemd tools from assuming they are init
run() { systemd-nspawn -q --register=no -D "$ROOT" /bin/bash -c "$*"; }

echo "==> Functional checks"

run "systemctl --version" \
    && echo "  OK: systemctl --version" \
    || { echo "  FAIL: systemctl --version"; exit 1; }

if run "homectl --help" 2>&1 | grep -qi 'birth-date'; then
    echo "  FAIL: homectl still has --birth-date"
    exit 1
else
    echo "  OK: homectl clean"
fi

run "systemd-analyze --help >/dev/null 2>&1" \
    && echo "  OK: systemd-analyze" \
    || { echo "  FAIL: systemd-analyze"; exit 1; }

echo "==> Boot test"

# Disable getty to prevent interactive login prompt
rm -f "$ROOT"/etc/systemd/system/getty.target.wants/getty@*.service
rm -f "$ROOT"/etc/systemd/system/autovt@.service

# Auto-poweroff after reaching multi-user.target
mkdir -p "$ROOT/etc/systemd/system/multi-user.target.wants"
cat > "$ROOT/etc/systemd/system/smoke-poweroff.service" <<'EOF'
[Unit]
Description=Auto-poweroff for smoke test
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/systemctl poweroff

[Install]
WantedBy=multi-user.target
EOF
ln -sf ../smoke-poweroff.service \
    "$ROOT/etc/systemd/system/multi-user.target.wants/smoke-poweroff.service"

# Run the boot test with a timeout
# Exit codes:
#   0   — clean shutdown (success)
#   124 — timeout fired, container did not shut down (failure)
#   143 — nspawn caught SIGTERM during shutdown (acceptable)
timeout 30 systemd-nspawn -q --register=no -D "$ROOT" --boot 2>&1 &
PID=$!
wait "$PID" 2>/dev/null
RC=$?

if (( RC == 124 )); then
    echo "  FAIL: container did not shut down within 30 seconds"
    exit 1
elif (( RC == 0 || RC == 143 )); then
    echo "  OK: boot + clean shutdown (exit code $RC)"
else
    echo "  FAIL: boot test exit code $RC"
    exit 1
fi

echo "==> All smoke tests passed"
