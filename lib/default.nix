{inputs}: let
  inherit (inputs) self;
in {
  nixpkgsConfig = system: {
    inherit system;
    overlays = import ../overlays/default.nix {inherit inputs;};
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "openssl-1.1.1w"
      ];
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
          (pkgs.fetchpatch2 {
            name = "shadps4-add-zenity.patch";
            url = "https://github.com/Sirius902/nixpkgs/commit/65d5989484ecc179b8dc1a864629a954da097be2.patch?full_index=1";
            hash = "sha256-wOEEgyNjViyvmAK71D0shNsQsiOWhKi07l9T/BpZ/MY=";
          })
          # Update pure-prompt https://github.com/NixOS/nixpkgs/pull/491292
          (pkgs.fetchpatch2 {
            name = "update-pure-prompt.patch";
            url = "https://github.com/Sirius902/nixpkgs/commit/36fca490d613fd05e006583340b8512f00cc118d.patch?full_index=1";
            hash = "sha256-zNZK/Q4x72FRpHReGHuI3YYyNry9yrnJGnmdxlxpZyI=";
          })
          # Add cosmic-ext-applet-clipboard-manager https://github.com/NixOS/nixpkgs/pull/496706
          (pkgs.fetchpatch2 {
            name = "add-cosmic-ext-applet-clipboard-manager.patch";
            url = "https://github.com/kritdass/nixpkgs/commit/71f8f21a50192425577f92f97eb5212a85dd0588.patch?full_index=1";
            hash = "sha256-TvrGKoaPnrkIZyntbv/C6m55e2p2kLECtxH7/fViXM4=";
          })
        ]
        ++ (extraPatches pkgs);
    };
}
