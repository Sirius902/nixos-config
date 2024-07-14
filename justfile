host := "nixlee"

fmt:
	nix --extra-experimental-features "nix-command flakes" fmt

switch:
	sudo nixos-rebuild --flake "path:{{ justfile_directory() }}#{{ host }}" switch

# Creates `/persist/passwords/chris` with the hashed password.
install-passwd:
	sudo mkdir -p /mnt/persist/passwords
	mkpasswd -m sha-512 > /tmp/chris
	sudo cp /tmp/chris /mnt/persist/passwords

# Run after:
# * Formatting with `disk-config.nix`.
# * Running `make install-passwd`.
# * Copying `secrets-example.nix` to `secrets.nix` and modifying secrets appropriately.
# * Modifying `host` above to match desired host.
# * If installing on a VM, edit `boot.zfs.devNodes` in `vm.nix` to be the boot partition.
install efi=(`df --output=source /mnt/efi | awk ' NR==2 '`):
	# Mount `/efi` with root-only permissions to avoid systemd complaining about a security hole.
	sudo umount "{{ efi }}"
	sudo mount -o umask=0077 "{{ efi }}" /mnt/efi

	sudo chmod -R g-rx,o-rx /mnt/persist/passwords/
	sudo nixos-generate-config --root /mnt
	sudo rsync -a "{{ justfile_directory() }}" /mnt/etc/nixos
	sudo nixos-install --flake "path:/mnt/etc/nixos#{{ host }}" --no-root-passwd
