HOST=nixlee

.PHONY: fmt
fmt:
	nix --extra-experimental-features "nix-command flakes" fmt

.PHONY: switch
switch:
	sudo nixos-rebuild --flake "path:#$(HOST)" switch

.PHONY: install
install:
	sudo nixos-install --flake "path:/mnt/etc/nixos#$(HOST)" --no-root-passwd
