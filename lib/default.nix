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
  }:
    nixpkgs.legacyPackages.${system}.applyPatches {
      name = "nixpkgs-patched";
      src = nixpkgs;
      patches = [
        # Update ZFS https://github.com/NixOS/nixpkgs/pull/493812
        (builtins.fetchurl {
          name = "update-zfs.patch";
          url = "https://github.com/NixOS/nixpkgs/compare/c9c494411139bf640b22c332f7a92b94e8454de2...25b22531399f1b99b2d2bc964b9f96b806a87fd0.patch?full_index=1";
          sha256 = "sha256:072c6s0w38v6hlysz349xdxnwr3xilg47hbfhy99ws040pjjbigq";
        })
        # Add shadps4-qt https://github.com/NixOS/nixpkgs/pull/474696
        # Some extra patches here https://github.com/Sirius902/nixpkgs/tree/shadps4-fixes
        (builtins.fetchurl {
          name = "shadps4-qt.patch";
          url = "https://github.com/Sirius902/nixpkgs/compare/aea86a71ccb9c1c0003507988271015397953833...c8f7707fb26d5d46c852fd7b23426fa8ea3697d9.patch?full_index=1";
          sha256 = "sha256:1qir2rwnnq46bxkl0qrdnx0q92qwiy7aqjgxidvb2c2iy2x1cpgc";
        })
      ];
    };
}
