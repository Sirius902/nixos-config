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
        # Add shadps4-qt https://github.com/NixOS/nixpkgs/pull/474696
        (builtins.fetchurl {
          name = "shadps4-qt.patch";
          url = "https://github.com/ryand56/nixpkgs/compare/2d4672af3da4241781d1e8f1483619450fa6155f...306c7efa8796bca0611b5434d53880d698e258ac.patch?full_index=1";
          sha256 = "sha256:0zbxzbp4sf41g6knd63v9hc15w3ffpvr5mp1ylxsdpz4wgrm0wrm";
        })
        # Update pure-prompt https://github.com/NixOS/nixpkgs/pull/491292
        (builtins.fetchurl {
          name = "update-pure-prompt.patch";
          url = "https://github.com/Sirius902/nixpkgs/commit/36fca490d613fd05e006583340b8512f00cc118d.patch?full_index=1";
          sha256 = "sha256:168s4zs3mri7f2v9wbzfqrynck831mny464xg3waapsqbnqspz5s";
        })
        (builtins.fetchurl {
          name = "linux_7_0-amdgpu-regression-fix.patch";
          url = "https://github.com/Sirius902/nixpkgs/commit/90857910e2c08f625d84c0b585c24a4b471a2295.patch?full_index=1";
          sha256 = "sha256:1dfdi6d3nffnr511dp0h9i076616bl5xlz78923wd8y599mgjszj";
        })
      ];
    };
}
