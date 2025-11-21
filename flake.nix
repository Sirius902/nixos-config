{
  description = "My NixOS and nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
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
    nixpkgs,
    nix-darwin,
    nvim-conf,
    flake-parts,
    ...
  } @ inputs: let
    importPkgs = system:
      import nixpkgs {
        inherit system;
        overlays = [
          (import ./pkgs/overlay.nix)
          (import ./overlays/moonlight.nix)

          nvim-conf.overlays.default

          # Add Switch 2 controller support via https://github.com/libsdl-org/SDL/pull/13327.
          (final: prev: {
            dolphin-emu = prev.dolphin-emu.override {sdl3 = prev.sdl3_git;};
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

          # Add graalvm-ce_8.
          (final: prev: let
            srcs = {
              "x86_64-linux" = {
                url = "https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-21.3.1/graalvm-ce-java8-linux-amd64-21.3.1.tar.gz";
                hash = "sha256-uey9VC3h7Qo9pGpinyJmqIIDJpj1/LxU2JI3K5GJsO0=";
              };
            };
          in {
            graalvmPackages =
              (prev.graalvmPackages or {})
              // {
                graalvm-ce_8 = prev.graalvmPackages.graalvm-ce.overrideAttrs (prevAttrs: {
                  version = "8";
                  src = final.fetchurl srcs.${final.stdenv.hostPlatform.system};
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
              };
          })

          (final: prev: {
            prismlauncher = prev.prismlauncher.overrideAttrs (prevAttrs: {
              qtWrapperArgs =
                (prevAttrs.qtWrapperArgs or [])
                ++ final.lib.optionals final.stdenv.hostPlatform.isLinux [
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
        ];
        config.allowUnfree = true;
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
        pkgs = importPkgs system;
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

      flake = {
        nixosConfigurations = let
          home-manager = inputs.home-manager.nixosModules.home-manager;

          hardwareConfigOr = cfg:
            if (builtins.pathExists ./hardware-configuration.nix)
            then ./hardware-configuration.nix
            else cfg;
        in {
          sirius-lee = let
            system = "x86_64-linux";
            pkgs = importPkgs system;
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

          nixtower = let
            system = "x86_64-linux";
            pkgs = importPkgs system;
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
            pkgs = importPkgs system;
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

                home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = args;
                  home-manager.users.chris = import ./modules/home/default.nix;
                }
              ];
            };
        };

        darwinConfigurations = let
          system = "aarch64-darwin";
          pkgs = importPkgs system;
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
