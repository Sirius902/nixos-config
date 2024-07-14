HOST := nixlee
ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: fmt
fmt:
	nix --extra-experimental-features "nix-command flakes" fmt

.PHONY: switch
switch:
	sudo nixos-rebuild --flake "path:#$(HOST)" switch

# Creates `/persist/passwords/chris` with the hashed password.
.PHONY: install-passwd
install-passwd:
	sudo mkdir -p /mnt/persist/passwords
	mkpasswd -m sha-512 > /tmp/chris
	sudo cp /tmp/chris /mnt/persist/passwords

# Run after:
# * Formatting with `disk-config.nix`.
# * Running `make install-passwd`.
# * Copying `secrets-example.nix` to `secrets.nix` and modifying secrets appropriately.
# * Modifying `HOST` above to match desired host.
.PHONY: install
install:
	# Mount `/efi` with root-only permissions to avoid systemd complaining about a security hole.
	$(eval EFI := $(shell df --output=source /mnt/efi | awk ' NR==2 '))
	sudo umount "$(EFI)"
	sudo mount -o umask=0077 "$(EFI)" /mnt/efi

	sudo chmod -R g-rx,o-rx /mnt/persist/passwords/
	sudo nixos-generate-config --root /mnt
	sudo rsync -a "$(ROOT_DIR)" /mnt/etc/nixos
	sudo nixos-install --flake "path:/mnt/etc/nixos#$(HOST)" --no-root-passwd
