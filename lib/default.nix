{inputs}: {
  nixosSystem = {
    system,
    host,
    nixpkgs ? inputs.nixpkgs,
    setHostName ? true,
    extraModules ? [],
  }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules =
        [
          (../. + "/hosts/${host}/configuration.nix")

          ({lib, ...}: {
            networking.hostName = lib.mkIf setHostName host;
          })
        ]
        ++ extraModules;
    };

  darwinSystem = {
    system,
    host,
    extraModules ? [],
  }:
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules =
        [
          (../. + "/hosts/${host}/configuration.nix")
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
