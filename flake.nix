{
  description = "My NixOS and nix-darwin configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-ghidra-fix.url = "github:nixos/nixpkgs?rev=3497aa5c9457a9d88d71fa93a4a8368816fbeeba";
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
              # Update rpcs3 https://github.com/NixOS/nixpkgs/pull/478577
              (builtins.fetchurl {
                name = "update-rpcs3.patch";
                url = "https://github.com/NixOS/nixpkgs/commit/4310884afc21f3f4c9de97eb0aef2acfd171084d.patch?full_index=1";
                sha256 = "sha256:074g2fjzy2ix5r0nvk0fwh98920zml6q168lbnmzz8vbx1zqnl10";
              })
            ];
          };
      in {
        lib = import ./lib/default.nix {inherit inputs;};

        nixosConfigurations = {
          sirius-lee = let
            inherit (inputs) nixpkgs;
            system = "x86_64-linux";
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
            inherit (inputs) nixpkgs;
            system = "x86_64-linux";
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
          allPackages = import ./pkgs/all-packages.nix {inherit pkgs;};
        in
          (lib.mapAttrs (name: _: pkgs.${name}) allPackages)
          // {
            inherit (pkgs) moonlight dolphin-emu;
            inherit (pkgs.graalvmPackages) graalvm-ce_8;
          };

        devShells.default = pkgs.mkShell {
          packages = [pkgs.just];
        };
      };
    };
}
