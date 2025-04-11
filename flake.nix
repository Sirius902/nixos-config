{
  description = "nixlee flake";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=nixos-unstable";
      # NOTE(Sirius902) This should be enabled when using cosmic.
      follows = "nixos-cosmic/nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-stable = {
      url = "github:nixos/nixpkgs?ref=nixos-24.11";
      # NOTE(Sirius902) This should be enabled when using cosmic.
      follows = "nixos-cosmic/nixpkgs-stable";
    };
    home-manager-stable = {
      url = "github:nix-community/home-manager?ref=release-24.11";
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
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    moonlight = {
      # TODO(Sirius902) Put back after pnpm 10 ends up in COSMIC nixpkgs.
      # url = "github:moonlight-mod/moonlight";
      url = "github:moonlight-mod/moonlight?rev=188b595ba267761d0e5fad0d943766042d680875";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-ghidra_11_2_1.url = "github:nixos/nixpkgs?rev=e0c16b06b5557975efe96961f9169d5e833a4d92";
  };

  outputs = {
    nixpkgs,
    home-manager,
    nixpkgs-stable,
    home-manager-stable,
    nix-darwin,
    nvim-conf,
    moonlight,
    flake-parts,
    nixpkgs-ghidra_11_2_1,
    ...
  } @ inputs: let
    importPkgs = {
      system,
      nixpkgs,
      isUnstable ? false,
    }:
      import nixpkgs {
        inherit system;
        overlays = [
          nvim-conf.overlays.default
          moonlight.overlays.default

          (final: prev: {
            ghostty-nautilus = final.callPackage ./pkgs/ghostty-nautilus/default.nix {};

            gcfeeder = final.callPackage ./pkgs/gcfeeder/default.nix {};

            gcfeederd = final.callPackage ./pkgs/gcfeederd/default.nix {};

            gcviewer = final.callPackage ./pkgs/gcviewer/default.nix {};

            ghidra-extensions =
              prev.ghidra-extensions
              // {
                gamecube-loader = nixpkgs-ghidra_11_2_1.legacyPackages.${system}.callPackage ./pkgs/ghidra-extensions/gamecube-loader/default.nix {};
              };

            shipwright = final.callPackage ./pkgs/shipwright/default.nix {};

            _2ship2harkinian = final.callPackage ./pkgs/_2ship2harkinian/default.nix {};
          })
        ];
        config.allowUnfree = true;
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
          packages.gcfeeder = gcfeeder;
          packages.gcviewer = gcviewer;
          packages.gcfeederd = gcfeederd;
          packages.gamecube-loader = ghidra-extensions.gamecube-loader;
          packages.shipwright = shipwright;
          packages._2ship2harkinian = _2ship2harkinian;

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
                  home-manager.users.chris = {
                    imports = [
                      ./modules/home/default.nix
                      # ./modules/home/gnome.nix
                      ./modules/home/cosmic.nix
                      ./modules/home/ghostty/default.nix
                      # ./modules/home/ghostty/gnome.nix
                      ./modules/home/gcviewer.nix
                      ./modules/home/gcfeederd.nix
                    ];
                  };
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
                  home-manager.users.chris = {
                    imports = [
                      ./modules/home/default.nix
                      # ./modules/home/gnome.nix
                      ./modules/home/cosmic.nix
                      ./modules/home/ghostty/default.nix
                      # ./modules/home/ghostty/gnome.nix
                      ./modules/home/gcviewer.nix
                      ./modules/home/gcfeederd.nix
                    ];
                  };
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
                  home-manager.users.chris = import ./modules/home/default.nix;
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
                  home-manager.users.chris = {
                    imports = [
                      ./modules/home/default.nix
                      ./modules/home/gnome.nix
                      ./modules/home/ghostty/default.nix
                      ./modules/home/ghostty/gnome.nix
                    ];
                  };
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
                  home-manager.users.chris = {
                    imports = [
                      ./modules/home/default.nix
                      ./modules/home/gnome.nix
                      ./modules/home/ghostty/default.nix
                      ./modules/home/ghostty/gnome.nix
                    ];
                  };
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
                  home-manager.users.chris = import ./modules/home/default.nix;
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
                  home-manager.users.chris = {
                    imports = [
                      ./modules/home/default.nix
                      # ./modules/home/gnome.nix
                      ./modules/home/ghostty/default.nix
                      # ./modules/home/ghostty/gnome.nix
                    ];
                  };
                }
              ];
            };
        };

        darwinConfigurations = let
          system = "aarch64-darwin";
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              inputs.nvim-conf.overlays.default
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
                home-manager.users.chris = {
                  imports = [
                    ./modules/home/default.nix
                    ./modules/home/ghostty/default.nix
                  ];
                };
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
