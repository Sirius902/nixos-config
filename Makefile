HOST := nixlee
ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: fmt
fmt:
	nix --extra-experimental-features "nix-command flakes" fmt

.PHONY: switch
switch:
	sudo nixos-rebuild --flake "path:#$(HOST)" switch

# Run after:
# * Formatting with `disk-config.nix`.
# * Creating `/persist/passwords/chris` with the hashed password.
#   * Generate with `mkpasswd -m sha-512`.
# * Copying `secrets-example.nix` to `secrets.nix` and modifying secrets appropriately.
# * Modifying `HOST` above to match desired host.
.PHONY: install
install: EFI := $(shell df --output=source /mnt/efi | awk ' NR==2 ')
install:
	# Mount `/efi` with root-only permissions to avoid systemd complaining about a security hole.
	sudo umount "$(EFI)"
	sudo mount -o umask=0077 "$(EFI)" /mnt/efi

	sudo chmod -R g-rx,o-rx /mnt/persist/passwords/
	sudo nixos-generate-config --root /mnt
	sudo rsync -a "$(ROOT_DIR)" /mnt/etc/nixos
	sudo nixos-install --flake "path:/mnt/etc/nixos#$(HOST)" --no-root-passwd
