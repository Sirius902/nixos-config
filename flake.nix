{
  description = "My NixOS and nix-darwin configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    flake-parts.url = "github:hercules-ci/flake-parts";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+ssh://git@github.com/Sirius902/nixos-secrets";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.sops-nix.follows = "sops-nix";
    };
    nvim-conf.url = "github:Sirius902/nvim-conf";
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      flake = let
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
              # Ghidra 12.0 https://github.com/NixOS/nixpkgs/pull/469200
              (builtins.fetchurl {
                name = "ghidra-12_0.patch";
                url = "https://github.com/NixOS/nixpkgs/compare/94a0d0855155c299df57ad5c39419465940c9362...165e21d5b4acd522e6efb9b88aac036b87a96874.patch?full_index=1";
                sha256 = "sha256:1hxpg0vdmfnwsvwphrcks429z94zlf7acvq8q9jzhvw9rsh02sdz";
              })
            ];
          };
      in {
        lib = import ./lib/default.nix {inherit inputs;};

        nixosConfigurations = {
          sirius-lee = let
            system = "x86_64-linux";
            nixpkgs = inputs.nixpkgs-unstable;
            nixpkgs' = patchNixpkgs {inherit system nixpkgs;};
            pkgs' = import nixpkgs' {
              inherit system;
              config.allowUnfree = true;
            };
          in
            self.lib.nixosSystem {
              inherit system nixpkgs;
              host = "sirius-lee";
              extraModules = [
                (import "${nixpkgs'}/nixos/modules/programs/librepods.nix")

                ({lib, ...}: {
                  nixpkgs.pkgs = pkgs';
                  nixpkgs.config = lib.mkForce {};
                })
              ];
            };

          nixtower = let
            system = "x86_64-linux";
            nixpkgs = inputs.nixpkgs-unstable;
            nixpkgs' = patchNixpkgs {inherit system nixpkgs;};
            pkgs' = import nixpkgs' {
              inherit system;
              config.allowUnfree = true;
            };
          in
            self.lib.nixosSystem {
              inherit system nixpkgs;
              host = "nixtower";
              extraModules = [
                (import "${nixpkgs'}/nixos/modules/programs/librepods.nix")

                ({lib, ...}: {
                  nixpkgs.pkgs = pkgs';
                  nixpkgs.config = lib.mkForce {};
                })
              ];
            };

          hee-ho = self.lib.nixosSystem {
            system = "x86_64-linux";
            host = "hee-ho";
          };

          iso = self.lib.nixosSystem {
            system = "x86_64-linux";
            host = "iso";
            setHostName = false;
          };

          netboot = self.lib.nixosSystem {
            system = "x86_64-linux";
            host = "netboot";
            setHostName = false;
          };

          raspberrypi = self.lib.nixosSystem {
            system = "aarch64-linux";
            host = "raspberrypi";
          };

          sd = self.lib.nixosSystem {
            system = "aarch64-linux";
            host = "sd";
            setHostName = false;
          };
        };

        darwinConfigurations = {
          Tralsebook-V2 = self.lib.darwinSystem {
            system = "aarch64-darwin";
            host = "Tralsebook-V2";
          };

          The-Rekening = self.lib.darwinSystem {
            system = "aarch64-darwin";
            host = "The-Rekening";
          };
        };
      };

      perSystem = {system, ...}: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = import ./overlays/default.nix {inherit inputs;};
          config.allowUnfree = true;
        };
        inherit (pkgs) lib;
      in {
        formatter = pkgs.alejandra;

        packages = let
          allPackages = import ./pkgs/all-packages.nix {inherit pkgs;};

          overlayedAllPackages =
            (lib.mapAttrs (name: _: pkgs.${name}) allPackages)
            // {
              inherit (pkgs) moonlight dolphin-emu;
              inherit (pkgs.graalvmPackages) graalvm-ce_8;
            };
        in
          overlayedAllPackages
          // {
            update = pkgs.writeShellApplication {
              name = "unstable-update";

              text = lib.concatStringsSep "\n" (
                lib.mapAttrsToList (
                  attr: drv:
                    if drv ? updateScript && (lib.isList drv.updateScript) && (lib.length drv.updateScript) > 0
                    then
                      lib.escapeShellArgs (
                        if (lib.match "nix-update|.*/nix-update" (lib.head drv.updateScript) != null)
                        then
                          [(lib.getExe pkgs.nix-update) "--flake"]
                          ++ (lib.tail drv.updateScript)
                          ++ ["--commit" attr]
                        else drv.updateScript
                      )
                    else builtins.toString drv.updateScript or ""
                )
                (builtins.removeAttrs overlayedAllPackages ["dolphin-emu" "graalvm-ce_8"])
              );
            };

            update-all = pkgs.writeShellScriptBin "update-all" ''
              ${self.packages.${system}.update}/bin/unstable-update
            '';
          };

        devShells.default = pkgs.mkShell {
          packages = [pkgs.just];
        };
      };
    };
}
