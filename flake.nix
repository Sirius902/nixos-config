{
  description = "My NixOS and nix-darwin configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-prev.url = "github:nixos/nixpkgs?rev=e4bae1bd10c9c57b2cf517953ab70060a828ee6f";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence?rev=5f42ef6c4a11af8541a7c3915afe783c9d485b86";
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
          sirius-lee = let
            inherit (inputs) nixpkgs;
            system = "x86_64-linux";
            nixpkgs' = self.lib.patchNixpkgs {inherit system nixpkgs;};
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
            inherit (inputs) nixpkgs;
            system = "x86_64-linux";
            nixpkgs' = self.lib.patchNixpkgs {inherit system nixpkgs;};
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

        apps = {
          update = {
            type = "app";
            program = let
              mkUpdate = attr: drv:
                if drv ? updateScript
                then let
                  injectArgs = cmd:
                    lib.replaceString "/bin/nix-update" ''/bin/nix-update "--flake" "--commit" "${attr}"''
                    (toString cmd);

                  cmd = injectArgs (lib.escapeShellArgs (lib.toList (drv.updateScript.command or drv.updateScript)));
                in ''
                  update_${attr}() {
                    ${cmd}
                  }
                ''
                else "";

              defaultPkgs = removeAttrs (self.packages.${system}) ["dolphin-emu" "graalvm-ce_8"];
            in
              lib.getExe (pkgs.writeShellScriptBin "update" ''
                ${lib.concatStringsSep "\n" (lib.mapAttrsToList mkUpdate self.packages.${system})}

                if [ "$#" -eq 0 ]; then
                  ${lib.concatStringsSep "\n"
                  (lib.mapAttrsToList
                    (attr: drv:
                      if drv ? updateScript
                      then "update_${attr}"
                      else "")
                    defaultPkgs)}
                else
                  for attr in "$@"; do
                    if declare -F "update_$attr" >/dev/null; then
                      "update_$attr"
                    else
                      echo "error: unknown or non-updatable attr '$attr'" >&2
                      exit 1
                    fi
                  done
                fi
              '');
            meta.description = "Updates packages and overlays for this flake.";
          };
        };

        packages = let
          nixpkgs' = self.lib.patchNixpkgs {
            inherit system;
            inherit (inputs) nixpkgs;
          };
          pkgs = import nixpkgs' {
            inherit system;
            overlays = import ./overlays/default.nix {inherit inputs;};
            config.allowUnfree = true;
          };
          allPackages = import ./pkgs/all-packages.nix {inherit pkgs;};
        in
          (lib.mapAttrs (name: _: pkgs.${name}) allPackages)
          // {
            inherit (pkgs) moonlight dolphin-emu shadps4-qt;
            inherit (pkgs.graalvmPackages) graalvm-ce_8;
          };

        devShells.default = pkgs.mkShell {
          packages = [pkgs.just];
        };
      };
    };
}
