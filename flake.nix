{
  description = "nixlee flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # TODO: Switch back once ZFS 2.3.0 stable comes out.
    #nixpkgs-stable.url = "github:nixos/nixpkgs?ref=nixos-24.05";
    nixpkgs-stable.url = "github:nixos/nixpkgs?rev=32e940c7c420600ef0d1ef396dc63b04ee9cad37";
    home-manager-stable = {
      url = "github:nix-community/home-manager?ref=release-24.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    # disko = {
    #   url = "github:nix-community/disko";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+ssh://git@github.com/Sirius902/nixos-secrets.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-nvim-config = {
      url = "github:Sirius902/nix-nvim-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
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
    ghostty = {
      url = "git+ssh://git@github.com/ghostty-org/ghostty";
      inputs.nixpkgs-stable.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nixpkgs-master,
    home-manager,
    nixpkgs-stable,
    home-manager-stable,
    nix-darwin,
    ghostty,
    flake-parts,
    ...
  } @ inputs: let
    importPkgs = {
      system,
      nixpkgs,
      isUnstable ? false,
    }:
      import nixpkgs {
        inherit system;
        overlays =
          [
            inputs.nix-nvim-config.overlays.default

            (final: prev: {
              ghostty = ghostty.packages.${system}.default;
            })

            (final: prev: {
              ghostty-nautilus = final.callPackage ./packages/ghostty-nautilus/default.nix {};
            })
          ]
          ++ (
            nixpkgs.legacyPackages.${system}.lib.optional isUnstable
            (final: prev: {
              # TODO(Sirius902) Overlay until https://github.com/NixOS/nixpkgs/pull/370126 makes it to nixos-unstable.
              openmw = nixpkgs-master.legacyPackages.${system}.openmw;

              # TODO(Sirius902) Overlay until https://github.com/NixOS/nixpkgs/pull/370350 makes it to nixos-unstable.
              jetbrains =
                prev.jetbrains
                // {
                  idea-community = nixpkgs-master.legacyPackages.${system}.jetbrains.idea-community;
                };
            })
          );
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            # TODO(Sirius902) Required by scarab. Remove if no longer necessary.
            "dotnet-runtime-6.0.36"
            "dotnet-sdk-6.0.428"
            "dotnet-sdk-wrapped-6.0.428"
            # TODO(Sirius902) Required by jetbrains.rider. Remove if no longer necessary.
            "dotnet-sdk-7.0.410"
          ];
        };
      };

    importPkgsUnstable = system:
      importPkgs {
        inherit system nixpkgs;
        isUnstable = true;
      };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = {system, ...}:
        with (importPkgsUnstable system); {
          formatter = alejandra;

          packages.ghostty-nautilus = ghostty-nautilus;

          devShells.default = mkShell {
            packages = [just];
          };
        };

      flake = {
        nixosConfigurations = let
          systemDeps = {
            system,
            nixpkgs,
            home-manager,
            isUnstable ? false,
          }: {
            inherit nixpkgs;
            pkgs = importPkgs {inherit system nixpkgs isUnstable;};
            home-manager = home-manager.nixosModules.home-manager;
            inputs =
              inputs
              // {
                inherit nixpkgs;
                home-manager = home-manager.nixosModules.home-manager;
              };
          };

          unstableDeps = system:
            systemDeps {
              inherit system nixpkgs home-manager;
              isUnstable = true;
            };
          stableDeps = system:
            systemDeps {
              inherit system;
              nixpkgs = nixpkgs-stable;
              home-manager = home-manager-stable;
            };

          hardwareConfigOr = cfg:
            if (builtins.pathExists ./hardware-configuration.nix)
            then ./hardware-configuration.nix
            else cfg;
        in {
          nixlee = let
            system = "x86_64-linux";
            inherit (unstableDeps system) pkgs nixpkgs home-manager inputs;
            args = nixpkgs.lib.attrsets.unionOfDisjoint inputs {
              hostname = "nixlee";
              hostId = "ff835154";
              isHeadless = false;
              isVm = false;
            };
          in
            nixpkgs.lib.nixosSystem {
              inherit system pkgs;
              specialArgs = args;
              modules = [
                ./configuration.nix
                ./hosts/nixlee.nix
                (hardwareConfigOr ./hardware/nixlee.nix)
                ./modules/nvidia.nix
                home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = args;
                  home-manager.users.chris = import ./home.nix;
                }
              ];
            };

          nixtower = let
            system = "x86_64-linux";
            inherit (unstableDeps system) pkgs nixpkgs home-manager inputs;
            args = nixpkgs.lib.attrsets.unionOfDisjoint inputs {
              hostname = "nixtower";
              hostId = "1a14084a";
              isHeadless = false;
              isVm = false;
            };
          in
            nixpkgs.lib.nixosSystem {
              inherit system pkgs;
              specialArgs = args;
              modules = [
                ./configuration.nix
                ./hosts/nixtower.nix
                (hardwareConfigOr ./hardware/nixtower.nix)
                ./modules/nvidia.nix
                home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = args;
                  home-manager.users.chris = import ./home.nix;
                }
              ];
            };

          hee-ho = let
            system = "x86_64-linux";
            inherit (stableDeps system) pkgs nixpkgs home-manager inputs;
            args = nixpkgs.lib.attrsets.unionOfDisjoint inputs {
              hostname = "hee-ho";
              hostId = "b0e08309";
              isHeadless = true;
              isVm = false;
            };
          in
            nixpkgs.lib.nixosSystem {
              inherit system pkgs;
              specialArgs = args;
              modules = [
                ./configuration.nix
                ./hosts/server.nix
                ./hosts/hee-ho.nix
                (hardwareConfigOr ./hardware/hee-ho.nix)

                # TODO: This conflicts with the manual hardware config. Decide which to use.
                # disko.nixosModules.disko
                # ./disk-config.nix
                # { disko.devices.disk.primary.device = "/dev/nvme0n1"; }

                home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = args;
                  home-manager.users.chris = import ./home.nix;
                }
              ];
            };

          nixpad = let
            system = "x86_64-linux";
            inherit (unstableDeps system) pkgs nixpkgs home-manager inputs;
            args = nixpkgs.lib.attrsets.unionOfDisjoint inputs {
              hostname = "nixpad";
              hostId = "1c029249";
              isHeadless = false;
              isVm = false;
            };
          in
            nixpkgs.lib.nixosSystem {
              inherit system pkgs;
              specialArgs = args;
              modules = [
                /configuration.nix
                ./hosts/nixpad.nix
                (hardwareConfigOr ./hardware/nixpad.nix)
                home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = args;
                  home-manager.users.chris = import ./home.nix;
                }
              ];
            };

          qemu = let
            system = "x86_64-linux";
            inherit (unstableDeps system) pkgs nixpkgs home-manager inputs;
            args = nixpkgs.lib.attrsets.unionOfDisjoint inputs {
              hostname = "vm";
              hostId = "1763015d";
              isHeadless = false;
              isVm = true;
            };
          in
            nixpkgs.lib.nixosSystem {
              inherit system pkgs;
              specialArgs = args;
              modules = [
                ./configuration.nix
                ./hosts/qemu.nix
                (hardwareConfigOr ./hardware/qemu.nix)

                # TODO: This conflicts with the manual hardware config. Decide which to use.
                # disko.nixosModules.disko
                # ./disk-config.nix
                # { disko.devices.disk.primary.device = "/dev/vda"; }

                home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = args;
                  home-manager.users.chris = import ./home.nix;
                }
              ];
            };

          qemu-server = let
            system = "x86_64-linux";
            inherit (stableDeps system) pkgs nixpkgs home-manager inputs;
            args = nixpkgs.lib.attrsets.unionOfDisjoint inputs {
              hostname = "vm-server";
              hostId = "f531a5e3";
              isHeadless = true;
              isVm = true;
            };
          in
            nixpkgs.lib.nixosSystem {
              inherit system pkgs;
              specialArgs = args;
              modules = [
                ./configuration.nix
                ./hosts/server.nix
                ./hosts/qemu.nix
                (hardwareConfigOr ./hardware/qemu.nix)

                # TODO: This conflicts with the manual hardware config. Decide which to use.
                # disko.nixosModules.disko
                # ./disk-config.nix
                # { disko.devices.disk.primary.device = "/dev/vda"; }

                home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = args;
                  home-manager.users.chris = import ./home.nix;
                }
              ];
            };

          vmware-aarch64 = let
            system = "aarch64-linux";
            inherit (unstableDeps system) pkgs nixpkgs home-manager inputs;
            args = nixpkgs.lib.attrsets.unionOfDisjoint inputs {
              hostname = "vm";
              hostId = "c5cb7a32";
              isHeadless = false;
              isVm = true;
            };
          in
            nixpkgs.lib.nixosSystem {
              inherit system pkgs;
              specialArgs = args;
              modules = [
                ./configuration.nix
                ./hosts/vmware.nix
                ./hardware-configuration.nix

                home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = args;
                  home-manager.users.chris = import ./home.nix;
                }
              ];
            };
        };

        darwinConfigurations = let
          system = "aarch64-darwin";
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              inputs.nix-nvim-config.overlays.default
            ];
            config.allowUnfree = true;
          };
          home-manager = inputs.home-manager.darwinModules.home-manager;

          args = nixpkgs.lib.attrsets.unionOfDisjoint inputs {
            isHeadless = false;
            isVm = false;
          };

          darwinConfig = nix-darwin.lib.darwinSystem {
            inherit system pkgs;
            specialArgs = args;
            modules = [
              ./darwin/configuration.nix

              home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.extraSpecialArgs = args;
                home-manager.users.chris = import ./home.nix;
              }
            ];
          };
        in {
          # Build darwin flake using:
          # $ darwin-rebuild build --flake .#Tralsebook
          "Tralsebook" = darwinConfig;
          "The-Rekening" = darwinConfig;
        };
      };
    };
}
