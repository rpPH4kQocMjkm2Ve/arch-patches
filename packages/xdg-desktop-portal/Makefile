PKGBASE     := xdg-desktop-portal
ARCH_PKG    := https://gitlab.archlinux.org/archlinux/packaging/packages/$(PKGBASE).git
CACHEDIR    ?= $(HOME)/.cache/arch-patches
BUILDDIR    := $(CACHEDIR)/$(PKGBASE)
CHROOT      ?= /var/lib/makechrootpkg

.PHONY: build test-quick clean

build: clean
	git clone --depth 1 $(ARCH_PKG) $(BUILDDIR)
	-cp patches/*.patch $(BUILDDIR)/
	cat pkgbuild.append >> $(BUILDDIR)/PKGBUILD
	cd $(BUILDDIR) && makechrootpkg -c -r $(CHROOT) -- --skippgpcheck

test-quick:
	bash test/quick-check.sh $(BUILDDIR)

clean:
	rm -rf $(BUILDDIR)
