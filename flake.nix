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
    nixpkgs-ghidra_11_2_1.url = "github:nixos/nixpkgs?rev=e0c16b06b5557975efe96961f9169d5e833a4d92";
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };
    # TODO(Sirius902) Remove once https://github.com/NixOS/nixpkgs/pull/313013 gets in.
    nixpkgs-zelda64recomp.url = "github:qubitnano/nixpkgs?rev=679b3f608a6774719fa6dd9df711a0bdcbbdc515";
  };

  outputs = {
    nixpkgs,
    home-manager,
    nixpkgs-stable,
    home-manager-stable,
    nix-darwin,
    nvim-conf,
    flake-parts,
    secrets,
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
              prev.zelda64recomp.overrideAttrs (prevAttrs: {
                postFixup =
                  (prevAttrs.postFixup or "")
                  + ''
                    wrapProgram $out/bin/Zelda64Recompiled \
                      --prefix LD_LIBRARY_PATH : ${final.lib.makeLibraryPath libs}
                  '';
              });
          })

          # Add extra patches for shipwright-anchor.
          (final: prev: {
            shipwright-anchor = prev.shipwright-anchor.overrideAttrs (prevAttrs: {
              patches = (prevAttrs.patches or []) ++ secrets.patches.shipwright-anchor;
            });
          })

          # TODO(Sirius902) Overlay new cosmic-comp until https://github.com/pop-os/cosmic-comp/pull/1481 makes it to nixos-unstable.
          (final: prev: {
            cosmic-comp = prev.cosmic-comp.overrideAttrs (finalAttrs: prevAttrs: {
              version = "1.0.0-alpha.7-unstable-${finalAttrs.env.VERGEN_GIT_COMMIT_DATE}";

              src = prevAttrs.src.override {
                tag = null;
                rev = "7a52eff61ed211964d4db765ed2ad3b8769ea205";
                hash = "sha256-tY0oee3s8rvwz3s3rxoTkhTpaLghvUSZWe+KCTjpZ1c=";
              };

              cargoHash = "sha256-B1Fknbivn2Vr5ZLucXLJ8//zHylNQogfFx7CtzRcU6Y=sha256-B1Fknbivn2Vr5ZLucXLJ8//zHylNQogfFx7CtzRcU6Y=";

              cargoDeps = final.rustPlatform.fetchCargoVendor {
                inherit (finalAttrs) pname src version;
                hash = finalAttrs.cargoHash;
              };

              env.VERGEN_GIT_COMMIT_DATE = "2025-07-04";
              env.VERGEN_GIT_SHA = finalAttrs.src.rev;
            });
          })

          # Update to graalvm-oracle 24.
          (final: prev: let
            srcs = {
              "aarch64-linux" = {
                hash = "sha256-dvJVfzLoz75ti3u/Mx8PCS674cw2omeOCYMFiSB2KYs=";
                url = "https://download.oracle.com/graalvm/24/archive/graalvm-jdk-24.0.2_linux-aarch64_bin.tar.gz";
              };
              "x86_64-linux" = {
                hash = "sha256-sBYaSbvB0PQGl1Mt36u4BSpaFeRjd15pRf4+SSAlm64=";
                url = "https://download.oracle.com/graalvm/24/archive/graalvm-jdk-24.0.2_linux-x64_bin.tar.gz";
              };
              "x86_64-darwin" = {
                hash = "sha256-3w+eXRASAcUL+muqPGV6gaKIPFtQl6n1q5PauG9+O6I=";
                url = "https://download.oracle.com/graalvm/24/archive/graalvm-jdk-24.0.2_macos-x64_bin.tar.gz";
              };
              "aarch64-darwin" = {
                hash = "sha256-LcdjTtk5xyXUGjU/c0Q/8y5w8vtXc2fxKmk2EH40lNw=";
                url = "https://download.oracle.com/graalvm/24/archive/graalvm-jdk-24.0.2_macos-aarch64_bin.tar.gz";
              };
            };
          in {
            graalvm-oracle =
              (prev.graalvm-oracle.override {
                version = "24";
              }).overrideAttrs (prevAttrs: {
                src = final.fetchurl srcs.${final.stdenv.system};
                meta =
                  prevAttrs.meta
                  // {
                    platforms = builtins.attrNames srcs;
                  };

                # Fix from https://github.com/NixOS/nixpkgs/pull/423224.
                propagatedBuildInputs = (prevAttrs.propagatedBuildInputs or []) ++ [final.onnxruntime];
                postFixup =
                  (prevAttrs.postFixup or "")
                  + ''
                    patchelf --replace-needed libonnxruntime.so.1.18.0 libonnxruntime.so.1 $out/lib/svm/profile_inference/onnx/native/libonnxruntime4j_jni.so
                  '';
              });
          })

          # TODO(Sirius902) Somehow `__structuredAttrs` breaks the `idea-community-mc-dev` derivation...
          (final: prev: {
            jetbrains = let
              override = pkg:
                pkg.overrideAttrs (_: {
                  separateDebugInfo = false;
                  __structuredAttrs = false;
                });
            in
              prev.jetbrains
              // {
                jdk = override prev.jetbrains.jdk;
                jdk-no-jcef = override prev.jetbrains.jdk-no-jcef;
                jdk-no-jcef-17 = override prev.jetbrains.jdk-no-jcef-17;
              };
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
        inherit (pkgs) lib;
      in {
        formatter = pkgs.alejandra;

        packages = let
          allPackages = import ./pkgs/all-packages.nix {
            inherit pkgs nixpkgs-ghidra_11_2_1;
          };

          overlayedAllPackages = lib.mapAttrs (name: _: pkgs.${name}) allPackages;
        in
          overlayedAllPackages
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
