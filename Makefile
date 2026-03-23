PACKAGES    := systemd
# PACKAGES  += xdg-desktop-portal
CHROOT      := /var/lib/makechrootpkg
REPODIR     ?= /var/cache/pacman/custom
REPONAME    ?= custom
CACHEDIR ?= $(or $(XDG_CACHE_HOME),$(HOME)/.cache)/arch-patches

.PHONY: all build test-quick test-smoke deploy \
        setup-chroot nuke-chroot sync-aur clean $(PACKAGES)

all: $(PACKAGES)

$(PACKAGES):
	$(MAKE) -C packages/$@ build CHROOT=$(CHROOT) CACHEDIR=$(CACHEDIR)
	$(MAKE) -C packages/$@ test-quick CACHEDIR=$(CACHEDIR)

build: $(PACKAGES)

test-quick:
	@for pkg in $(PACKAGES); do \
		$(MAKE) -C packages/$$pkg test-quick CACHEDIR=$(CACHEDIR); \
	done

test-smoke:
	@for pkg in $(PACKAGES); do \
		sudo $(MAKE) -C packages/$$pkg test-smoke CACHEDIR=$(CACHEDIR); \
	done

deploy:
	@for pkg in $(PACKAGES); do \
		bash deploy/push.sh $(CACHEDIR)/$$pkg $(REPODIR) $(REPONAME); \
	done

sync-aur:
	@for pkg in $(PACKAGES); do \
		bash scripts/sync-aur.sh $$pkg; \
	done

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

clean:
	@for pkg in $(PACKAGES); do \
		$(MAKE) -C packages/$$pkg clean CACHEDIR=$(CACHEDIR); \
	done
