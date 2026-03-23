# arch-patches

[![CI](https://github.com/rpPH4kQocMjkm2Ve/arch-patches/actions/workflows/check.yml/badge.svg)](https://github.com/rpPH4kQocMjkm2Ve/arch-patches/actions/workflows/check.yml)
![License](https://img.shields.io/github/license/rpPH4kQocMjkm2Ve/arch-patches)

Arch Linux packages rebuilt with age-verification and surveillance
infrastructure removed.

## Packages

### systemd

Removes the user birth date field introduced in systemd 261:

- `birthDate` field from user records (JSON, struct, serialization)
- `--birth-date` flag from `homectl`
- `parse_birth_date()` / `parse_calendar_date_full()` — reverted to
  `parse_calendar_date()`
- Birth date display in `user-record-show.c`
- PII sensitivity marking for `realName`, `location`, `emailAddress`
  (reverted to only marking `secret`)
- Related tests and documentation

Patch based on [r4shsec/systemd-no-age-verification](https://github.com/r4shsec/systemd-no-age-verification).

See [`packages/systemd/patches/0001-revert-age-verification.patch`](packages/systemd/patches/0001-revert-age-verification.patch)
for the full diff.

### xdg-desktop-portal (monitoring)

A [draft PR](https://github.com/flatpak/xdg-desktop-portal/pull/1922)
proposes a `ParentalControls` portal with a `QueryAgeBracket` D-Bus method
that lets sandboxed apps query the user's age range. This has not been merged
yet. When it is, a patch will be added here.

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

### Building a single package

```bash
make systemd
```

### Updating

When upstream releases a new version:

```bash
make clean
make
make deploy
sudo pacman -Syu
```

If a patch fails to apply, CI will have already flagged it via the daily
check workflow.

## What gets built

### systemd

The standard Arch `systemd` split packages with the patch applied:

- `systemd`
- `systemd-libs`
- `systemd-sysvcompat`
- `systemd-debug`
- `systemd-resolvconf`
- `systemd-tests`
- `systemd-ukify`

Version is the same as upstream with `.1` appended to `pkgrel`
(e.g. `261-1` → `261-1.1`).

## Testing

```bash
make test-quick             # check binaries for remnants (no root)
sudo make test-smoke        # install in nspawn container and boot
```

## AUR

```bash
make sync-aur               # generate AUR files for all packages
bash scripts/sync-aur.sh systemd   # single package
```

Generated files go to `packages/<name>/aur/`.

## CI

A daily GitHub Actions workflow
([`.github/workflows/check.yml`](.github/workflows/check.yml)) runs three
checks for systemd:

- **systemd-extract** — downloads and unpacks the current Arch source
- **systemd-code-present** — checks whether the age-verification code
  (`birthDate` / `birth_date`) has appeared in the Arch package (not present
  in 260, expected in 261+)
- **systemd-patch-applies** — verifies patches apply cleanly (only runs
  when the code is present)

CI also monitors the `xdg-desktop-portal`
[ParentalControls PR](https://github.com/flatpak/xdg-desktop-portal/pull/1922)
and checks whether the code has landed in the upstream `main` branch or Arch
packaging. If it has, CI will fail until a removal patch is added.

## Project structure

```
.
├── Makefile                              # top-level orchestrator
├── packages/
│   ├── systemd/
│   │   ├── patches/                      # git-format patches
│   │   │   └── 0001-revert-age-verification.patch
│   │   ├── pkgbuild.append              # appended to upstream PKGBUILD
│   │   ├── aur/                         # generated AUR package files
│   │   └── test/
│   │       ├── quick-check.sh           # strings-based binary check
│   │       └── smoke.sh                 # nspawn install + boot test
│   └── xdg-desktop-portal/             # prepared, not yet active
│       ├── patches/
│       ├── pkgbuild.append
│       └── test/
├── deploy/
│   └── push.sh                          # copy packages to local pacman repo
├── scripts/
│   └── sync-aur.sh                      # generate AUR files per package
└── .github/workflows/
    └── check.yml                        # daily patch + upstream checks
```

Build artifacts are kept out of the source tree:

```
~/.cache/arch-patches/
├── systemd/              # cloned upstream + built packages
└── xdg-desktop-portal/
```

Override with `CACHEDIR=…` (e.g. `make CACHEDIR=/tmp/build`).
```


## License

LGPL-2.1-or-later — same as systemd and xdg-desktop-portal.
