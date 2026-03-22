PKGBASE     := systemd
ARCH_PKG    := https://gitlab.archlinux.org/archlinux/packaging/packages/$(PKGBASE).git
BUILDDIR    := .build
CHROOT      ?= /var/lib/makechrootpkg

.PHONY: check-upstream build test-quick test-smoke clean

check-upstream:
	@echo "==> Installed:"
	@pacman -Q systemd systemd-libs 2>/dev/null || echo "  not installed"
	@echo "==> Upstream:"
	@pacman -Si systemd 2>/dev/null | grep -E '^(Version|Repository)'

build: clean
	git clone --depth 1 $(ARCH_PKG) $(BUILDDIR)
	cp patches/*.patch $(BUILDDIR)/
	cat pkgbuild.append >> $(BUILDDIR)/PKGBUILD
	cd $(BUILDDIR) && makechrootpkg -c -r $(CHROOT) -- --skippgpcheck

test-quick:
	bash test/quick-check.sh $(BUILDDIR)

test-smoke:
	bash test/smoke.sh $(BUILDDIR)

clean:
	rm -rf $(BUILDDIR)
