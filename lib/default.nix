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
          # Add shadps4-qt https://github.com/NixOS/nixpkgs/pull/474696
          (pkgs.fetchpatch2 {
            name = "shadps4-qt.patch";
            url = "https://github.com/ryand56/nixpkgs/compare/2d4672af3da4241781d1e8f1483619450fa6155f...306c7efa8796bca0611b5434d53880d698e258ac.patch?full_index=1";
            hash = "sha256-xkjfmRy9rJRwWxst/AXp1Imj7UtanR2CgIbWW1ojbj4=";
            excludes = ["pkgs/by-name/sh/shadps4/package.nix"];
          })
          # TODO(Sirius902) shadps4-qt patch does not apply cleanly...
          (pkgs.fetchpatch2 {
            name = "shadps4-fixes.patch";
            url = "https://github.com/Sirius902/nixpkgs/compare/a0c87fd9a4a7d620fc31adf1bab143afd9a6712c...6fc9aeda805963a2dd67e9485f7e1f48fd7af76e.patch?full_index=1";
            hash = "sha256-WUJrdtpLDTwnSMDHMYwuuFXNDfnreM8yM12eiPNkPMM=";
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
          # Fix fetchgit non-determinism https://github.com/NixOS/nixpkgs/pull/524430
          (pkgs.fetchpatch2 {
            name = "fetchgit-disable-maintenance.patch";
            url = "https://github.com/me-and/nixpkgs/commit/011471c7f24920fb29e18124da24232d9faf29b0.patch?full_index=1";
            hash = "sha256-CgBC2jq9IcjUrWgWSeXhvKJOJMdJ+KWwsBxxqY//5F0=";
          })
          # Fix fetchgit non-determinism for submodules https://github.com/NixOS/nixpkgs/pull/525255
          (pkgs.fetchpatch2 {
            name = "fetchgit-disable-maintenance-via-env.patch";
            url = "https://github.com/thefossguy/nixpkgs/commit/88cfc54552d5678f27d292fd75df963aecd3b357.patch?full_index=1";
            hash = "sha256-x5139yPSao3+j4FbXRoNQtpvW7Ou1NImXcbxoGUOJlc=";
          })
        ]
        ++ (extraPatches pkgs);
    };
}
