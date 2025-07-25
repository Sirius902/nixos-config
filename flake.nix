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
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };
    nixpkgs-ghidra_11_2_1.url = "github:nixos/nixpkgs?rev=e0c16b06b5557975efe96961f9169d5e833a4d92";
    # TODO(Sirius902) Remove once https://github.com/NixOS/nixpkgs/pull/313013 gets in.
    nixpkgs-zelda64recomp.url = "github:qubitnano/nixpkgs?rev=679b3f608a6774719fa6dd9df711a0bdcbbdc515";
    nixpkgs-jetbrains-jdk-fix.url = "github:Janrupf/nixpkgs?rev=6895a8b63bbdcbdeac7d8f0a332893c2ebbc2498";
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
    nixos-cosmic,
    nixpkgs-ghidra_11_2_1,
    nixpkgs-zelda64recomp,
    nixpkgs-jetbrains-jdk-fix,
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
            inherit (nixos-cosmic.outputs.packages.${system}) observatory;
          })

          (final: prev: let
            pkgs = import nixpkgs-zelda64recomp {inherit system config;};
          in {
            inherit
              (pkgs)
              n64recomp
              z64decompress
              zelda64recomp
              ;
          })

          # Use newer version of sdl3 with fix for https://github.com/libsdl-org/sdl2-compat/issues/491.
          # And adding Switch 2 controller support via https://github.com/libsdl-org/SDL/pull/13327.
          (final: prev: let
            sdl3 = prev.sdl3.overrideAttrs (finalAttrs: prevAttrs: {
              version = "db29f89";
              src = prevAttrs.src.override {
                tag = null;
                rev = finalAttrs.version;
                hash = "sha256-u8PyjZZ2JPUGBtxZ1R3dA3xLGp3EhfyaJ0Utf/hu41U=";
              };
              patches =
                (prevAttrs.patches or [])
                ++ [
                  (final.fetchpatch {
                    name = "switch2-controllers";
                    url = "https://github.com/flibitijibibo/SDL/commit/9b17353e046e74ba1abc936b87dbac040c123eb1.patch";
                    hash = "sha256-nW+j/TEieeyOXzGvGIxBcpg5rbqin1ENlEJ3kuBTO2Q=";
                  })
                ];
            });
            SDL2 = (prev.SDL2.override {inherit sdl3;}).overrideAttrs (finalAttrs: prevAttrs: {
              version = "a9b8494";
              src = prevAttrs.src.override {
                tag = null;
                rev = finalAttrs.version;
                hash = "sha256-xPbr+OW1Jdyfbc8pn+0N4nThb8U5MHBeHcNdIydR5wo=";
              };
            });
          in {
            shipwright = prev.shipwright.override {inherit SDL2;};
            _2ship2harkinian = prev._2ship2harkinian.override {inherit SDL2;};
            shipwright-anchor = prev.shipwright-anchor.override {inherit SDL2;};
            zelda64recomp = prev.zelda64recomp.override {inherit SDL2;};
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
                rev = "7f814a445c40234211fc194d1f9ac9341f823d76";
                hash = "sha256-Rzb8kkX8iaXPVklAG5D78hNNl2SbTBoDh/q4Z0nyEOE=";
              };

              cargoHash = "sha256-B1Fknbivn2Vr5ZLucXLJ8//zHylNQogfFx7CtzRcU6Y=";

              cargoDeps = final.rustPlatform.fetchCargoVendor {
                inherit (finalAttrs) pname src version;
                hash = finalAttrs.cargoHash;
              };

              env.VERGEN_GIT_COMMIT_DATE = "2025-07-18";
              env.VERGEN_GIT_SHA = finalAttrs.src.rev;
            });
          })

          # Update to graalvm-oracle 24.
          (final: prev: let
            srcs = {
              "aarch64-linux" = {
                url = "https://download.oracle.com/graalvm/24/archive/graalvm-jdk-24.0.2_linux-aarch64_bin.tar.gz";
                hash = "sha256-dvJVfzLoz75ti3u/Mx8PCS674cw2omeOCYMFiSB2KYs=";
              };
              "x86_64-linux" = {
                url = "https://download.oracle.com/graalvm/24/archive/graalvm-jdk-24.0.2_linux-x64_bin.tar.gz";
                hash = "sha256-sBYaSbvB0PQGl1Mt36u4BSpaFeRjd15pRf4+SSAlm64=";
              };
              "x86_64-darwin" = {
                url = "https://download.oracle.com/graalvm/24/archive/graalvm-jdk-24.0.2_macos-x64_bin.tar.gz";
                hash = "sha256-3w+eXRASAcUL+muqPGV6gaKIPFtQl6n1q5PauG9+O6I=";
              };
              "aarch64-darwin" = {
                url = "https://download.oracle.com/graalvm/24/archive/graalvm-jdk-24.0.2_macos-aarch64_bin.tar.gz";
                hash = "sha256-LcdjTtk5xyXUGjU/c0Q/8y5w8vtXc2fxKmk2EH40lNw=";
              };
            };
          in rec {
            graalvm-oracle_24 =
              (prev.graalvm-oracle.override {
                version = "24";
              }).overrideAttrs (finalAttrs: prevAttrs:
                final.lib.optionalAttrs (prevAttrs.version == "24") {
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
            graalvm-oracle = graalvm-oracle_24;
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

          # TODO(Sirius902) Remove once https://github.com/NixOS/nixpkgs/pull/426285 makes it to nixos-unstable.
          (final: prev: let
            pkgs = import nixpkgs-jetbrains-jdk-fix {inherit system config;};
          in {
            inherit (pkgs) jetbrains;
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
          // rec {
            inherit
              (pkgs)
              n64recomp
              z64decompress
              zelda64recomp
              ;

            sdl3 = pkgs.sdl3.overrideAttrs (finalAttrs: prevAttrs: {
              version = "db29f89";
              src = prevAttrs.src.override {
                tag = null;
                rev = finalAttrs.version;
                hash = "sha256-u8PyjZZ2JPUGBtxZ1R3dA3xLGp3EhfyaJ0Utf/hu41U=";
              };
              patches =
                (prevAttrs.patches or [])
                ++ [
                  (pkgs.fetchpatch {
                    name = "switch2-controllers";
                    url = "https://github.com/flibitijibibo/SDL/commit/9b17353e046e74ba1abc936b87dbac040c123eb1.patch";
                    hash = "sha256-nW+j/TEieeyOXzGvGIxBcpg5rbqin1ENlEJ3kuBTO2Q=";
                  })
                ];
            });

            SDL2 = (pkgs.SDL2.override {inherit sdl3;}).overrideAttrs (finalAttrs: prevAttrs: {
              version = "a9b8494";
              src = prevAttrs.src.override {
                tag = null;
                rev = finalAttrs.version;
                hash = "sha256-xPbr+OW1Jdyfbc8pn+0N4nThb8U5MHBeHcNdIydR5wo=";
              };
            });
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
