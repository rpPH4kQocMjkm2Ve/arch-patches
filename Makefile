PACKAGES    := systemd
# PACKAGES  += xdg-desktop-portal
CHROOT      := /var/lib/makechrootpkg
REPODIR     ?= /var/cache/pacman/custom
REPONAME    ?= custom

.PHONY: all build test-quick test-smoke deploy \
        setup-chroot nuke-chroot sync-aur clean $(PACKAGES)

all: $(PACKAGES)

$(PACKAGES):
	$(MAKE) -C packages/$@ build CHROOT=$(CHROOT)
	$(MAKE) -C packages/$@ test-quick

build: $(PACKAGES)

test-quick:
	@for pkg in $(PACKAGES); do \
		$(MAKE) -C packages/$$pkg test-quick; \
	done

test-smoke:
	@for pkg in $(PACKAGES); do \
		sudo $(MAKE) -C packages/$$pkg test-smoke; \
	done

deploy:
	@for pkg in $(PACKAGES); do \
		bash deploy/push.sh packages/$$pkg/.build $(REPODIR) $(REPONAME); \
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
		$(MAKE) -C packages/$$pkg clean; \
	done
