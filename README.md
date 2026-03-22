# systemd-no-age

Arch Linux systemd packages with age-verification infrastructure (`birthDate`,
`--birth-date`) removed.

This removes the user birth date field introduced in systemd 261 from
`homectl`, `user-record`, documentation and tests. Nothing else is changed.

## Why

systemd added a `birthDate` field to user records and a `--birth-date` flag to
`homectl`. This is unnecessary PII collection at the init system level. This
project maintains a patch that reverts it.

## Install

### Prerequisites

- Arch Linux
- [devtools](https://archlinux.org/packages/extra/any/devtools/) (`sudo pacman -S devtools`)
- A build chroot (`make setup-chroot`)

### Build and install

```bash
make setup-chroot   # one-time
make                # clone upstream, patch, build, quick-check
make deploy         # copy packages to local repo
sudo pacman -Syu    # install from local repo
```

The default local repo is `/var/cache/pacman/custom`. Make sure your
`/etc/pacman.conf` includes it:

```ini
[custom]
SigLevel = Optional TrustAll
Server = file:///var/cache/pacman/custom
```

### Updating

When upstream releases a new systemd version:

```bash
make clean
make
make deploy
sudo pacman -Syu
```

If the patch fails to apply, CI will have already flagged it via the daily
check workflow.

## What gets built

The standard Arch `systemd` split packages with the patch applied:

- `systemd`
- `systemd-libs`
- `systemd-sysvcompat`
- `systemd-debug`
- `systemd-resolvconf`
- `systemd-tests`
- `systemd-ukify`

Version is the same as upstream with `.1` appended to `pkgrel`
(e.g. `260-1.1`).

## What the patch removes

- `birthDate` field from user records (JSON, struct, serialization)
- `--birth-date` flag from `homectl`
- `parse_birth_date()` / `parse_calendar_date_full()` — reverted to
  `parse_calendar_date()`
- Birth date display in `user-record-show.c`
- PII sensitivity marking for `realName`, `location`, `emailAddress`
  (reverted to only marking `secret`)
- Related tests and documentation

See [`patches/0001-revert-age-verification.patch`](patches/0001-revert-age-verification.patch)
for the full diff.

## Testing

```bash
make test-quick             # check binaries for birthDate strings (no root)
sudo make test-smoke        # install in nspawn container and boot
```

## CI

A daily GitHub Actions workflow ([`.github/workflows/check.yml`](.github/workflows/check.yml))
verifies the patch still applies to the latest upstream PKGBUILD. If systemd
does not contain the age-verification code upstream, CI will report the patch as
obsolete.

## Project structure

```
.
├── patches/                 # git-format patch(es) against systemd source
│   └── 0001-revert-age-verification.patch
├── pkgbuild.append          # appended to upstream PKGBUILD (adds patch + bumps pkgrel)
├── deploy/
│   └── push.sh              # copy built packages to local pacman repo
├── test/
│   ├── quick-check.sh       # strings-based binary check
│   └── smoke.sh             # nspawn install + boot test
├── Makefile                 # build/test/deploy workflow
└── .github/workflows/
    └── check.yml            # daily patch applicability check
```

## License

LGPL-2.1-or-later — same as systemd.
