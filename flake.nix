{
  description = "My NixOS and nix-darwin configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?rev=23735a82a828372c4ef92c660864e82fbe2f5fbe";
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

      flake = {
        lib = import ./lib/default.nix {inherit inputs;};

        nixosConfigurations = {
          sirius-lee = self.lib.nixosSystem {
            system = "x86_64-linux";
            host = "sirius-lee";
            nixpkgs = inputs.nixpkgs-unstable;
          };

          nixtower = self.lib.nixosSystem {
            system = "x86_64-linux";
            host = "nixtower";
            nixpkgs = inputs.nixpkgs-unstable;
          };

          hee-ho = self.lib.nixosSystem {
            system = "x86_64-linux";
            host = "hee-ho";
          };

          iso = self.lib.nixosSystem {
            system = "x86_64-linux";
            host = "iso";
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
