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
        # Add librepods https://github.com/NixOS/nixpkgs/pull/444137
        (builtins.fetchurl {
          name = "add-librepods.patch";
          url = "https://github.com/NixOS/nixpkgs/compare/78a51b69699c3f6b366dc5c2fb62a567b8334459...1c229bf6f394e65227854061b7d7e5ffa7753ae5.patch?full_index=1";
          sha256 = "sha256:1b8nny6k1vyyc1lnf123br5w0p006sj8r8ac65v9afk0cgvd0cay";
        })
        # Update rpcs3 https://github.com/NixOS/nixpkgs/pull/478577
        (builtins.fetchurl {
          name = "update-rpcs3.patch";
          url = "https://github.com/NixOS/nixpkgs/commit/4310884afc21f3f4c9de97eb0aef2acfd171084d.patch?full_index=1";
          sha256 = "sha256:074g2fjzy2ix5r0nvk0fwh98920zml6q168lbnmzz8vbx1zqnl10";
        })
        # Add shadps4-qt https://github.com/NixOS/nixpkgs/pull/474696
        # Some extra patches here https://github.com/Sirius902/nixpkgs/tree/shadps4-fixes
        (builtins.fetchurl {
          name = "shadps4-qt.patch";
          url = "https://github.com/Sirius902/nixpkgs/compare/8cab1e45e3c6a80b1c531c804bedfc1a5ddf8c70...4b16a7787c9366d96e57a4c428fbed798dfc477f.patch?full_index=1";
          sha256 = "sha256:15d9nbc6ini1zvd7640xfzm4nr20k8gizllz9vjzarh96x3825hb";
        })
      ];
    };
}
