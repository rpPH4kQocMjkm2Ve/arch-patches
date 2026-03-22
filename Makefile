PKGBASE   := systemd
ARCH_PKG  := https://gitlab.archlinux.org/archlinux/packaging/packages/$(PKGBASE).git
BUILDDIR  := .build
CHROOT    := /var/lib/makechrootpkg
REPODIR   ?= /var/cache/pacman/custom
REPONAME  ?= custom

.PHONY: all build test-quick test-smoke deploy \
        setup-chroot nuke-chroot check-upstream sync-aur clean

all: build
	bash test/quick-check.sh $(BUILDDIR)

build: clean
	git clone --depth 1 $(ARCH_PKG) $(BUILDDIR)
	cp patches/*.patch $(BUILDDIR)/
	cat pkgbuild.append >> $(BUILDDIR)/PKGBUILD
	cd $(BUILDDIR) && makechrootpkg -c -r $(CHROOT) -- --skippgpcheck

test-quick:
	bash test/quick-check.sh $(BUILDDIR)

test-smoke:
	sudo bash test/smoke.sh $(BUILDDIR)

deploy:
	bash deploy/push.sh $(BUILDDIR) $(REPODIR) $(REPONAME)

sync-aur:
	bash scripts/sync-aur.sh

setup-chroot:
	@if [ -d "$(CHROOT)/root" ]; then \
		echo "==> Chroot exists, updating..."; \
		sudo arch-nspawn $(CHROOT)/root pacman -Syu --noconfirm; \
	else \
		sudo mkdir -p $(CHROOT); \
		sudo mkarchroot $(CHROOT)/root base-devel; \
	fi

nuke-chroot:
	sudo rm -rf $(CHROOT)
	$(MAKE) setup-chroot

check-upstream:
	@echo "==> Installed:"
	@pacman -Q systemd systemd-libs 2>/dev/null || echo "  not installed"
	@echo "==> Upstream:"
	@pacman -Si systemd 2>/dev/null | grep -E '^(Version|Repository)'

clean:
	rm -rf $(BUILDDIR)
