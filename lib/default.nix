{inputs}: let
  inherit (inputs) self;
in {
  nixpkgsConfig = system: {
    inherit system;
    overlays = import ../overlays/default.nix {inherit inputs;};
    config = {
      allowUnfree = true;
    };
  };

  nixosSystem = {
    system,
    host,
    setHostName ? true,
    extraModules ? [],
    extraPatches ? _pkgs: [],
  }: let
    patchedSrc = inputs.self.lib.patchNixpkgs {
      inherit system extraPatches;
      inherit (inputs) nixpkgs;
    };
    patchedPkgs = import patchedSrc (self.lib.nixpkgsConfig system);
  in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules =
        [
          (../. + "/hosts/${host}/configuration.nix")

          ({lib, ...}: {
            networking.hostName = lib.mkIf setHostName host;
            nixpkgs.pkgs = patchedPkgs;
          })
        ]
        ++ extraModules;
    };

  darwinSystem = {
    system,
    host,
    extraModules ? [],
    extraPatches ? _pkgs: [],
  }: let
    patchedSrc = inputs.self.lib.patchNixpkgs {
      inherit system extraPatches;
      inherit (inputs) nixpkgs;
    };
    patchedPkgs = import patchedSrc (self.lib.nixpkgsConfig system);
  in
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules =
        [
          (../. + "/hosts/${host}/configuration.nix")

          {
            nixpkgs.pkgs = patchedPkgs;
          }
        ]
        ++ extraModules;
    };

  patchNixpkgs = {
    system,
    nixpkgs,
    extraPatches ? _pkgs: [],
  }: let
    pkgs = nixpkgs.legacyPackages.${builtins.currentSystem or system};
  in
    pkgs.applyPatches {
      name = "nixpkgs-patched";
      src = nixpkgs;
      patches =
        [
          # TODO(Sirius902) shadps4 needs zenity for errors. Make PR?
          (pkgs.fetchpatch {
            name = "shadps4-add-zenity.patch";
            url = "https://github.com/NixOS/nixpkgs/commit/e7a9edbc8788feb0d0c6b4a52772f2641a46c53d.diff";
            hash = "sha256-/Ma6rOMuBZc5dL6V+Y9Y7N7begg7iONua3zJcfUlrOE=";
          })
          # Add cosmic-ext-applet-clipboard-manager https://github.com/NixOS/nixpkgs/pull/496706
          (pkgs.fetchpatch {
            name = "add-cosmic-ext-applet-clipboard-manager.patch";
            url = "https://github.com/NixOS/nixpkgs/commit/71f8f21a50192425577f92f97eb5212a85dd0588.diff";
            hash = "sha256-TvrGKoaPnrkIZyntbv/C6m55e2p2kLECtxH7/fViXM4=";
          })
        ]
        ++ (extraPatches pkgs);
    };
}
