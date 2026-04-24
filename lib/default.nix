{inputs}: {
  nixosSystem = {
    system,
    host,
    setHostName ? true,
    extraModules ? [],
  }: let
    patchedSrc = inputs.self.lib.patchNixpkgs {
      inherit system;
      inherit (inputs) nixpkgs;
    };
    patchedPkgs = import patchedSrc {
      inherit system;
      config.allowUnfree = true;
    };
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
            nixpkgs.config = lib.mkForce {};
          })
        ]
        ++ extraModules;
    };

  darwinSystem = {
    system,
    host,
    extraModules ? [],
  }: let
    patchedSrc = inputs.self.lib.patchNixpkgs {
      inherit system;
      inherit (inputs) nixpkgs;
    };
    patchedPkgs = import patchedSrc {
      inherit system;
      config.allowUnfree = true;
    };
  in
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules =
        [
          (../. + "/hosts/${host}/configuration.nix")

          ({lib, ...}: {
            nixpkgs.pkgs = patchedPkgs;
            nixpkgs.config = lib.mkForce {};
          })
        ]
        ++ extraModules;
    };

  patchNixpkgs = {
    system,
    nixpkgs,
  }: let
    pkgs = nixpkgs.legacyPackages.${system};
  in
    pkgs.applyPatches {
      name = "nixpkgs-patched";
      src = nixpkgs;
      patches = [
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
        # COSMIC 1.0.11
        (pkgs.fetchpatch2 {
          name = "cosmic-1_0_11.patch";
          url = "https://github.com/NixOS/nixpkgs/compare/274c537c291b53d4e7315d423da8d4ae38d7528f...a52a7021a88f52e8fcf663ef3acca58482f0c541.patch?full_index=1";
          hash = "sha256-RlY7VXH/EitWWFORd4yTvt6IQJAQ1QchFjp+Fdmpvek=";
        })
      ];
    };
}
