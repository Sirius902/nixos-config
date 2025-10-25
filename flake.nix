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
    # TODO(Sirius902) Override new derivation to be the old one to get rid of another nixpkgs?
    nixpkgs-ghidra_11_2_1.url = "github:nixos/nixpkgs?rev=e0c16b06b5557975efe96961f9169d5e833a4d92";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixpkgs-stable,
    home-manager-stable,
    nix-darwin,
    nvim-conf,
    flake-parts,
    secrets,
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
          (import ./pkgs/overlay.nix {inherit nixpkgs-ghidra_11_2_1;})
          (import ./overlays/moonlight.nix)

          nvim-conf.overlays.default

          # Add Switch 2 controller support via https://github.com/libsdl-org/SDL/pull/13327.
          (final: prev: {
            dolphin-emu = prev.dolphin-emu.override {SDL2 = prev.SDL2_git;};
          })

          # FUTURE(Sirius902) Rando fork for macOS?
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

          # Add extra patches for shipwright-anchor and shipwright-ap.
          (final: prev: {
            shipwright-anchor = prev.shipwright-anchor.overrideAttrs (prevAttrs: {
              patches = (prevAttrs.patches or []) ++ secrets.patches.shipwright-anchor;
            });

            shipwright-ap = prev.shipwright-ap.overrideAttrs (prevAttrs: {
              patches = (prevAttrs.patches or []) ++ secrets.patches.shipwright-ap;
            });
          })

          # Add graalvm-oracle_25.
          (final: prev: let
            srcs = {
              "aarch64-linux" = {
                url = "https://download.oracle.com/graalvm/25/archive/graalvm-jdk-25.0.1_linux-aarch64_bin.tar.gz";
                hash = "sha256-7dd1ZcdlcKbfXzjlPVRSQQLywbHPdO69n1Hn/Bn2Z80=";
              };
              "x86_64-linux" = {
                url = "https://download.oracle.com/graalvm/25/archive/graalvm-jdk-25.0.1_linux-x64_bin.tar.gz";
                hash = "sha256-1KsCuhAp5jnwM3T9+RwkLh0NSQeYgOGvGTLqe3xDGDc=";
              };
              "x86_64-darwin" = {
                url = "https://download.oracle.com/graalvm/25/archive/graalvm-jdk-25.0.1_macos-x64_bin.tar.gz";
                hash = "sha256-p2LKHZoWPjJ5C5KG869MFjaXKf8nmZ2NurYNe+Fs/y8=";
              };
              "aarch64-darwin" = {
                url = "https://download.oracle.com/graalvm/25/archive/graalvm-jdk-25.0.1_macos-aarch64_bin.tar.gz";
                hash = "sha256-Gd/UmtES5ubCve3FB8aFm/ISlPpMFk8b5nDUacZbeZM=";
              };
            };
          in {
            graalvm-oracle_25 = prev.graalvm-oracle.overrideAttrs (prevAttrs: {
              version = "25.0.1";
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

          # Add graalvm-ce_8.
          (final: prev: let
            srcs = {
              "x86_64-linux" = {
                url = "https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-21.3.1/graalvm-ce-java8-linux-amd64-21.3.1.tar.gz";
                hash = "sha256-uey9VC3h7Qo9pGpinyJmqIIDJpj1/LxU2JI3K5GJsO0=";
              };
            };
          in {
            graalvm-ce_8 = prev.graalvm-ce.overrideAttrs (prevAttrs: {
              version = "8";
              src = final.fetchurl srcs.${final.stdenv.system};
              meta =
                prevAttrs.meta
                // {
                  platforms = builtins.attrNames srcs;
                };

              postInstall = ''
                # jni.h expects jni_md.h to be in the header search path.
                ln -sf $out/include/linux/*_md.h $out/include/

                mkdir -p $out/share
                # move files in $out like LICENSE.txt
                find $out/ -maxdepth 1 -type f -exec mv {} $out/share \;

                # copy-paste openjdk's preFixup
                # Set JAVA_HOME automatically.
                mkdir -p $out/nix-support
                cat > $out/nix-support/setup-hook << EOF
                if [ -z "\''${JAVA_HOME-}" ]; then export JAVA_HOME=$out; fi
                EOF
              '';

              installCheckPhase = ''
                runHook preInstallCheck

                echo ${final.lib.escapeShellArg ''
                  public class HelloWorld {
                    public static void main(String[] args) {
                      System.out.println("Hello World");
                    }
                  }
                ''} > HelloWorld.java
                $out/bin/javac HelloWorld.java

                # run on JVM with Graal Compiler
                echo "Testing GraalVM"
                $out/bin/java -XX:+UnlockExperimentalVMOptions -XX:+EnableJVMCI -XX:+UseJVMCICompiler HelloWorld | fgrep 'Hello World'

                runHook postInstallCheck
              '';
            });
          })

          (final: prev: {
            prismlauncher = prev.prismlauncher.overrideAttrs (prevAttrs: {
              qtWrapperArgs =
                (prevAttrs.qtWrapperArgs or [])
                ++ final.lib.optionals final.stdenv.isLinux [
                  # Use xwayland for Prism Launcher. Running with wayland on system glfw
                  # makes my Ctrl+A input do Ctrl+A followed by A. :(
                  # TODO(Sirius902) Open an issue on nixpkgs for this?
                  "--unset WAYLAND_DISPLAY"
                  # Java is cronge, some RLCraft mod fails to initialize without fontconfig
                  # in `LD_LIBRARY_PATH`.
                  "--prefix LD_LIBRARY_PATH : ${final.lib.makeLibraryPath [final.fontconfig]}"
                ];
            });
          })

          (final: prev: {
            jetbrains =
              prev.jetbrains
              // {
                rider = prev.jetbrains.rider.overrideAttrs (prevAttrs: let
                  runtimeDependencies = [final.icu];
                in {
                  buildInputs = (prevAttrs.buildInputs or []) ++ runtimeDependencies;
                  postFixup =
                    (prevAttrs.postFixup or "")
                    + ''
                      wrapProgram $out/bin/rider \
                        --prefix LD_LIBRARY_PATH : ${final.lib.makeLibraryPath runtimeDependencies}
                    '';
                });
              };
          })

          # TODO(Sirius902) Remove this when we get https://github.com/NixOS/nixpkgs/pull/454184.
          (final: prev: {
            qt6Packages =
              prev.qt6Packages
              // {
                fcitx5-qt = prev.qt6Packages.fcitx5-qt.overrideAttrs (prevAttrs: {
                  patches =
                    (prevAttrs.patches or [])
                    ++ [
                      (final.fetchpatch2 {
                        url = "https://github.com/fcitx/fcitx5-qt/commit/46a07a85d191fd77a1efc39c8ed43d0cd87788d2.patch?full_index=1";
                        hash = "sha256-qv8Rj6YoFdMQLOB2R9LGgwCHKdhEji0Sg67W37jSIac=";
                      })
                      (final.fetchpatch2 {
                        url = "https://github.com/fcitx/fcitx5-qt/commit/6ac4fdd8e90ff9c25a5219e15e83740fa38c9c71.patch?full_index=1";
                        hash = "sha256-x0OdlIVmwVuq2TfBlgmfwaQszXLxwRFVf+gEU224uVA=";
                      })
                      (final.fetchpatch2 {
                        url = "https://github.com/fcitx/fcitx5-qt/commit/1d07f7e8d6a7ae8651eda658f87ab0c9df08bef4.patch?full_index=1";
                        hash = "sha256-22tKD7sbsTJcNqur9/Uf+XAvMvA7tzNQ9hUCMm+E+E0=";
                      })
                    ];
                });
              };
          })

          # TODO(Sirius902) Remove this when we get https://github.com/NixOS/nixpkgs/pull/455600.
          (final: prev: {
            openmw = prev.openmw.overrideAttrs (prevAttrs: {
              patches =
                (prevAttrs.patches or [])
                ++ [
                  (final.fetchpatch2 {
                    url = "https://raw.githubusercontent.com/Sirius902/nixpkgs/c7db3c41e6a6b60e25538aff086ac3e24c6fb985/pkgs/by-name/op/openmw/0001-Do-not-implicitly-convert-QByteArray-to-const-char.patch";
                    hash = "sha256-wYe93m8w/q8hJsCXBagkJ7ah/tT3UKmppkYYjjHAve8=";
                  })
                ];
            });
          })

          # TODO(Sirius902) Remove this when we get https://github.com/NixOS/nixpkgs/pull/454951.
          (final: prev: {
            dolphin-emu-beta = prev.dolphin-emu-beta.overrideAttrs (prevAttrs: {
              patches =
                (prevAttrs.patches or [])
                ++ [
                  (final.fetchpatch2 {
                    url = "https://github.com/dolphin-emu/dolphin/commit/8edef722ce1aae65d5a39faf58753044de48b6e0.patch?full_index=1";
                    hash = "sha256-QEG0p+AzrExWrOxL0qRPa+60GlL0DlLyVBrbG6pGuog=";
                  })
                ];
            });
          })

          # TODO(Sirius902) Remove this when we get https://github.com/NixOS/nixpkgs/pull/455193.
          (final: prev: {
            melonDS = prev.melonDS.overrideAttrs (prevAttrs: {
              version = "1.0-unstable-2025-10-24";
              src = prevAttrs.src.override {
                rev = "420a1fa7e75121d5f9de2a886b5c2742563d9a3d";
                hash = "sha256-g0mTmv5eIrCIra2Bp/LV9ZOAmXUaDaOIFwc+Fufp7p8=";
              };
              buildInputs = (prevAttrs.buildInputs or []) ++ [final.faad2];
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
        inherit (pkgs) lib;
      in {
        formatter = pkgs.alejandra;

        packages = let
          allPackages = import ./pkgs/all-packages.nix {
            inherit pkgs nixpkgs-ghidra_11_2_1;
          };

          overlayedAllPackages =
            (lib.mapAttrs (name: _: pkgs.${name}) allPackages)
            // {inherit (pkgs) moonlight dolphin-emu graalvm-oracle_25 graalvm-ce_8;};
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
                (builtins.removeAttrs overlayedAllPackages ["dolphin-emu" "graalvm-oracle_25" "graalvm-ce_8"])
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
          sirius-lee = let
            system = "x86_64-linux";
            inherit (unstableDeps system) pkgs nixpkgs home-manager inputs;
            args = nixpkgs.lib.attrsets.unionOfDisjoint inputs {
              hostname = "sirius-lee";
              hostId = "49e32584";
              isHeadless = false;
              isVm = false;
            };
          in
            nixpkgs.lib.nixosSystem {
              inherit system pkgs;
              specialArgs = args;
              modules = [
                ./configuration.nix
                ./hosts/sirius-lee.nix
                (hardwareConfigOr ./hardware/sirius-lee.nix)
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
                pkgs.shipwright-anchor
                pkgs.shipwright-ap
                pkgs._2ship2harkinian
              ];
            })
          ];
          "The-Rekening" = darwinConfig [];
        };
      };
    };
}
