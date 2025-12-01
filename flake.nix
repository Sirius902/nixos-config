{
  description = "My NixOS and nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
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
            dolphin-emu = prev.dolphin-emu.override {sdl3 = final.sdl3_git;};
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

          # Make NSO GameCube triggers digital for ship-like derivations.
          (final: prev:
            if prev.stdenv.hostPlatform.isLinux
            then
              # On Linux, set `SDL_GAMECONTROLLERCONFIG` to override the hidapi binding (setting it in sdl_gamecontrollerdb is not sufficient).
              prev.lib.mapAttrs (name: bin:
                prev.${name}.overrideAttrs (prevAttrs: {
                  postFixup =
                    (prevAttrs.postFixup or "")
                    + ''
                      wrapProgram ${bin} \
                        --suffix SDL_GAMECONTROLLERCONFIG $'\n' \
                          "030046457e0500007320000001016800,Nintendo GameCube Controller,a:b0,b:b1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,guide:b4,leftshoulder:b6,lefttrigger:b10,leftx:a0,lefty:a1,rightshoulder:b7,righttrigger:b11,rightx:a2,righty:a3,start:b5,x:b2,y:b3,misc1:b8,misc2:b9,hint:!SDL_GAMECONTROLLER_USE_GAMECUBE_LABELS:=1,"
                    '';
                })) {
                shipwright = "$out/lib/soh.elf";
                shipwright-ap = "$out/lib/soh.elf";
                _2ship2harkinian = "$out/lib/2s2h.elf";
                zelda64recomp = "$out/bin/Zelda64Recompiled";
              }
            else if prev.stdenv.hostPlatform.isDarwin
            then
              # On Darwin the hidapi driver isn't usable without entitlements so just treat it as a regular controller and init hid via a separate program.
              prev.lib.genAttrs ["shipwright" "shipwright-ap" "_2ship2harkinian"] (
                name:
                  prev.${name}.override {
                    sdl_gamecontrollerdb = final.sdl_gamecontrollerdb.overrideAttrs (prevAttrs: {
                      postInstall =
                        (prevAttrs.postInstall or "")
                        + ''
                          echo "030046457e0500007320000001010000,Nintendo GameCube Controller,crc:4546,platform:macOS,a:b1,b:b3,dpdown:b8,dpleft:b10,dpright:b9,dpup:b11,guide:b16,leftshoulder:b13,lefttrigger:b12,leftx:a0,lefty:a1~,misc1:b17,misc2:b20,rightshoulder:b5,righttrigger:b4,rightx:a2,righty:a3~,start:b6,x:b0,y:b2,hint:!SDL_GAMECONTROLLER_USE_GAMECUBE_LABELS:=1," >> $out/share/gamecontrollerdb.txt
                        '';
                    });
                  }
              )
            else {})

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

          iso = nixpkgs.lib.nixosSystem {
            specialArgs = {inherit inputs;};
            modules = [
              ./hosts/iso/configuration.nix
            ];
          };

          raspberrypi = nixpkgs.lib.nixosSystem {
            specialArgs = {inherit inputs;};
            modules = [
              ./hosts/raspberrypi/configuration.nix
            ];
          };

          sd = nixpkgs.lib.nixosSystem {
            specialArgs = {inherit inputs;};
            modules = [
              ./hosts/sd/configuration.nix
            ];
          };

          netboot = nixpkgs.lib.nixosSystem {
            specialArgs = {inherit inputs;};
            modules = [
              ./hosts/netboot/configuration.nix
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
