{
  description = "My NixOS and nix-darwin configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
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
    nixos-hardware.url = "github:NixOS/nixos-hardware";
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
        "aarch64-darwin"
      ];

      flake = {
        lib = import ./lib/default.nix {inherit inputs;};

        nixosConfigurations = {
          sirius-lee = self.lib.nixosSystem {
            system = "x86_64-linux";
            host = "sirius-lee";
            extraPatches = pkgs: [
              # Bump ZFS version
              (pkgs.fetchpatch2 {
                name = "zfs-bump.patch";
                url = "https://github.com/Sirius902/nixpkgs/compare/85eb70255b4311b60ec4cb6379907da0fcfdf230...922a53036b2d883c0f816f6697bda784655c0599.patch?full_index=1";
                hash = "sha256-mBZ4MBiJAM9SJrz9By/cCa5kde3HK+QhKVTSJx3RhI4=";
              })
            ];
          };

          nixtower = self.lib.nixosSystem {
            system = "x86_64-linux";
            host = "nixtower";
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
        pkgs = import inputs.nixpkgs (self.lib.nixpkgsConfig system);
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

              defaultPkgs = self.packages.${system};
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
          patchedPkgs = import nixpkgs' (self.lib.nixpkgsConfig system);
          allPackages = import ./pkgs/all-packages.nix {pkgs = patchedPkgs;};
        in
          (lib.mapAttrs (name: _: patchedPkgs.${name}) allPackages)
          // {
            inherit (patchedPkgs) claude-code poptracker moonlight rpcs3 shadps4 shadps4-qt archipelago n64recomp z64decompress zelda64recomp zellij cosmic-ext-applet-clipboard-manager;
            inherit (patchedPkgs.graalvmPackages) graalvm-ce_8;
          };

        checks.statix = pkgs.runCommandLocal "statix-check" {} ''
          ${lib.getExe pkgs.statix} check ${self} --config ${self}/statix.toml
          touch $out
        '';

        devShells.default = pkgs.mkShell {
          packages = [pkgs.just pkgs.statix];
        };
      };
    };
}
