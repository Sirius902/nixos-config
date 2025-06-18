{
  description = "nixlee flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-stable.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    home-manager-stable = {
      url = "github:nix-community/home-manager?ref=release-25.05";
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
    moonlight = {
      url = "github:moonlight-mod/moonlight";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-ghidra_11_2_1.url = "github:nixos/nixpkgs?rev=e0c16b06b5557975efe96961f9169d5e833a4d92";
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    # TODO(Sirius902) Remove once https://github.com/NixOS/nixpkgs/pull/313013 gets in.
    nixpkgs-zelda64recomp.url = "github:qubitnano/nixpkgs?rev=529fb9abd291092dbb6e7b9dec8d06e0f7cb4ad2";
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
    nixos-cosmic,
    nixpkgs-zelda64recomp,
    ...
  } @ inputs: let
    importPkgs = {
      system,
      nixpkgs,
      isUnstable ? false,
    }:
      import nixpkgs rec {
        inherit system;
        overlays = [
          (import ./pkgs/overlay.nix {inherit nixpkgs-ghidra_11_2_1;})

          nvim-conf.overlays.default
          moonlight.overlays.default

          (final: prev: {
            observatory = nixos-cosmic.outputs.packages.${system}.observatory;
          })

          (final: prev: let
            pkgs = import nixpkgs-zelda64recomp {inherit system config;};
          in {
            n64recomp = pkgs.n64recomp;
            z64decompress = pkgs.z64decompress;
            zelda64recomp = pkgs.zelda64recomp;
          })

          # Use newer version of sdl3 with fix for https://github.com/libsdl-org/sdl2-compat/issues/491.
          (final: prev: let
            sdl3 = prev.sdl3.overrideAttrs (finalAttrs: prevAttrs: {
              version = "b70919e";
              src = prevAttrs.src.override {
                tag = null;
                rev = finalAttrs.version;
                hash = "sha256-q5cLNtg5ZCRrrbngrVQhGG1lUOIZeSkaW35NIj6Eqso=";
              };
            });
            SDL2 = prev.SDL2.override {inherit sdl3;};
          in {
            shipwright = prev.shipwright.override {inherit SDL2;};
            _2ship2harkinian = prev._2ship2harkinian.override {inherit SDL2;};
            shipwright-anchor = prev.shipwright-anchor.override {inherit SDL2;};
            zelda64recomp = prev.zelda64recomp.override {inherit SDL2;};
          })

          # Add extra libs for MMRecompRando.
          (final: prev: {
            zelda64recomp = let
              libs = [
                final.openssl_3
                final.zlib
                final.stdenv.cc.cc.lib
              ];
            in
              prev.zelda64recomp.overrideAttrs (_: prevAttrs: {
                buildInputs = (prevAttrs.buildInputs or []) ++ libs;

                postFixup =
                  (prevAttrs.postFixup or "")
                  + ''
                    wrapProgram $out/bin/Zelda64Recompiled \
                      --prefix LD_LIBRARY_PATH : ${final.lib.makeLibraryPath libs}
                  '';
              });
          })

          # Overlay openrazer until https://github.com/NixOS/nixpkgs/pull/413803 makes it
          # to nixos-unstable.
          (final: prev: let
            override = finalAttrs: prevAttrs: {
              version = "3.10.3";
              src = prevAttrs.src.override {
                tag = "v${finalAttrs.version}";
                hash = "sha256-M5g3Rn9WuyudhWQfDooopjexEgGVB0rzfJsPg+dqwn4=";
              };
            };
          in {
            openrazer = prev.openrazer.overrideAttrs override;
            linuxPackages_6_15 = prev.linuxPackages_6_15.extend (_: lpprev: {
              openrazer = lpprev.openrazer.overrideAttrs override;
            });
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

      perSystem = {system, ...}: let
        pkgs = importPkgsUnstable system;
      in {
        formatter = pkgs.alejandra;

        packages =
          import ./pkgs/all-packages.nix {
            inherit pkgs nixpkgs-ghidra_11_2_1;
          }
          // {
            n64recomp = pkgs.n64recomp;
            z64decompress = pkgs.z64decompress;
            zelda64recomp = pkgs.zelda64recomp;
          };

        devShells.default = pkgs.mkShell {
          packages = [pkgs.just];
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
                ./configuration.nix
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
          pkgs = importPkgsUnstable system;
          home-manager = inputs.home-manager.darwinModules.home-manager;

          args = nixpkgs.lib.attrsets.unionOfDisjoint inputs {
            isHeadless = false;
            isVm = false;
          };

          darwinConfig = extraModules:
            nix-darwin.lib.darwinSystem {
              inherit system pkgs;
              specialArgs = args;
              modules =
                [
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
                ]
                ++ extraModules;
            };
        in {
          "Tralsebook" = darwinConfig [
            ({pkgs, ...}: {
              environment.systemPackages = [
                pkgs.shipwright
                pkgs._2ship2harkinian
                pkgs.shipwright-anchor
              ];
            })
          ];
          "The-Rekening" = darwinConfig [];
        };
      };
    };
}
