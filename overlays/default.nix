{inputs}: [
  (final: prev: let
    pkgs = import inputs.nixpkgs-dotnet {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  in {
    xivlauncher = prev.xivlauncher.override {
      inherit
        (pkgs)
        buildDotnetModule
        dotnetCorePackages
        ;
    };

    jetbrains =
      prev.jetbrains
      // {
        inherit (pkgs.jetbrains) rider;
      };
  })

  (import ../pkgs/overlay.nix)
  (import ./moonlight/default.nix)

  inputs.nvim-conf.overlays.default

  (final: prev: {
    cosmic-comp = prev.cosmic-comp.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.0.11";
      src = prevAttrs.src.override {
        hash = "sha256-4QvJONL+jel8QsDv3xShQyGe6nvlRV4b1Lkspy/MkpA=";
      };
      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname version src;
        hash = "sha256-80xojIrLd8Foxu9Qbf/cCImP4T4I7otA1iJbr7/lEb8=";
      };
    });
  })

  # FUTURE(Sirius902) https://github.com/pop-os/cosmic-comp/issues/2307
  (final: prev: {
    cosmic-comp = prev.cosmic-comp.overrideAttrs (prevAttrs: {
      patches =
        (prevAttrs.patches or [])
        ++ [
          (final.fetchpatch2 {
            name = "revert-2204.patch";
            url = "https://github.com/pop-os/cosmic-comp/commit/3a0b1ae5d24b48dad1d6a8655ce778362f61d7b3.patch?full_index=1";
            hash = "sha256-Y8MFdkNiT0VBLUc0KL3V36maQ1sDwV5kSO0wuifoJbs=";
            revert = true;
          })
          (final.fetchpatch2 {
            name = "revert-2147.patch";
            url = "https://github.com/pop-os/cosmic-comp/commit/1dc9c53a415905153d36f2a04d1c8389b5dfe222.patch?full_index=1";
            hash = "sha256-3kbC2AUBDFh2wD7nEIg9MTz42BHPJ4/5zCI1bdyRBSs=";
            revert = true;
          })
        ];
    });
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
          passthru = removeAttrs (prevAttrs.passthru or {}) ["updateScript"];

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

  (final: prev: {
    gamescope = prev.gamescope.overrideAttrs (prevAttrs: {
      patches =
        (prevAttrs.patches or [])
        ++ [
          (final.fetchpatch2 {
            name = "add-window-cycle.patch";
            url = "https://github.com/Sirius902/gamescope/commit/40641060430bfdf2a7e96832058fd41a86e59f46.patch?full_index=1";
            hash = "sha256-PTt0hQrbfWXiPCppJwRamcMqyb2iNmXyMXv8wkLgjIc=";
          })
          ../patches/gamescope/0001-main-Strip-gameoverlayrenderer.so-from-gamescope-s-o.patch
          (final.fetchpatch2 {
            name = "clamp-cursor-adaptive-sync.patch";
            url = "https://github.com/ValveSoftware/gamescope/commit/2b18c4eee02bc8600ce11705cada906e6bbe8232.patch?full_index=1";
            hash = "sha256-5ssDVIlQYBZlk5xcFSMbt9gAjsmM7Jv/IEM7R+4pF/M=";
          })
        ];

      # FUTURE(Sirius902) Disable fast math to fix blurriness on Wayland.
      # https://github.com/ValveSoftware/gamescope/issues/1622
      NIX_CFLAGS_COMPILE = (prevAttrs.NIX_CFLAGS_COMPILE or []) ++ ["-fno-fast-math"];
    });
  })

  (final: prev: {
    rpcs3 = prev.rpcs3.overrideAttrs (prevAttrs: {
      version = "0.0.40-unstable-2026-04-22";
      src = prevAttrs.src.override {
        tag = null;
        rev = "80b6faef10015be460b463f8426aa889d65b226e";
        hash = "sha256-vW4Lvmf2Q2iXf/QM7qbS/Q67/u4163upkp1i7eLv7sU=";
      };

      postPatch =
        (prevAttrs.postPatch or "")
        + ''
          PROTOBUF_DIR="$PWD/rpcs3/Emu/NP/generated"
          protoc --cpp_out="$PROTOBUF_DIR" --proto_path="$PROTOBUF_DIR" "$PROTOBUF_DIR/np2_structs.proto"

          sed -i '/COMMAND protoc/d' 3rdparty/protobuf/CMakeLists.txt
        '';

      cmakeFlags =
        (prevAttrs.cmakeFlags or [])
        ++ [
          (final.lib.cmakeBool "USE_SYSTEM_PROTOBUF" true)
        ];

      nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [final.protobuf_33];

      buildInputs = (prevAttrs.buildInputs or []) ++ [final.protobuf_33];

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {extraArgs = ["--version=branch"];};
        };
    });
  })

  (final: prev: {
    shadps4 = prev.shadps4.overrideAttrs (prevAttrs: {
      version = "0.15.0-unstable-2026-04-21";

      src = prevAttrs.src.override {
        tag = null;
        rev = "2b7d54f785c936706809a802b10f5bfb0d2759ad";
        hash = "sha256-DrN2rmRxuk6kvCjQOFkmwNJ9Lj9WcNiw9WlLqWeySY8=";
        fetchSubmodules = false;

        leaveDotGit = false;
        postCheckout = ''
          cd "$out"

          # Only fetch required submodules
          git -C externals submodule update --init --depth 1 \
            ImGuiFileDialog \
            LibAtrac9 \
            aacdec/fdk-aac \
            cpp-httplib \
            dear_imgui \
            discord-rpc \
            glslang \
            hwinfo \
            libusb \
            minimp3 \
            sirit \
            spdlog \
            tracy \
            zydis
          git -C externals/sirit submodule update --init --depth 1 externals/SPIRV-Headers

          git rev-parse --short=8 HEAD > $out/COMMIT
          date -u -d "@$(git log -1 --pretty=%ct)" "+%Y-%m-%dT%H:%M:%SZ" > $out/SOURCE_DATE_EPOCH
        '';
      };

      cmakeFlags =
        (prevAttrs.cmakeFlags or [])
        ++ [
          (final.lib.cmakeBool "SPDLOG_FMT_EXTERNAL" true)
        ];

      buildInputs =
        (prevAttrs.buildInputs or [])
        ++ [
          final.cli11
          final.libpng
          final.miniz
          final.nlohmann_json
          final.openal-soft
          final.sdl3
        ];

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version=branch"
              "--version-regex=v\\.(.*)"
            ];
          };
        };
    });
  })

  (
    final: prev: {
      shadps4-qt = prev.shadps4-qt.overrideAttrs (prevAttrs: {
        version = "0-unstable-2026-04-20";

        src = prevAttrs.src.override {
          tag = null;
          rev = "6487f9b0a2c24dbfb2773e67f5c77236afd933d5";
          hash = "sha256-6MuPItWD6TlDv1OVailaICHYJ60b+TLGnd4dFlLFFSg=";
          fetchSubmodules = false;

          leaveDotGit = false;
          postCheckout = ''
            cd "$out"

            # Only fetch required submodules
            git -C externals submodule update --init --depth 1 \
              json \
              spdlog \
              volk

            git rev-parse --short=8 HEAD > $out/COMMIT
            date -u -d "@$(git log -1 --pretty=%ct)" "+%Y-%m-%dT%H:%M:%SZ" > $out/SOURCE_DATE_EPOCH
          '';
        };

        cmakeFlags =
          (prevAttrs.cmakeFlags or [])
          ++ [
            (final.lib.cmakeBool "SPDLOG_FMT_EXTERNAL" true)
          ];

        passthru =
          (prevAttrs.passthru or {})
          // {
            updateScript = final.nix-update-script {
              extraArgs = [
                "--version=branch"
                "--version-regex=(0-unstable-.*)"
              ];
            };
          };
      });
    }
  )

  (final: prev: {
    hlsdk-portable = prev.hlsdk-portable.overrideAttrs (prevAttrs: {
      patches =
        (prevAttrs.patches or [])
        ++ [
          (final.fetchpatch2 {
            name = "npc-door-panic.patch";
            url = "https://github.com/Sirius902/hlsdk-portable/compare/6ba528f2a36622a45c453f832934ab3adaca7c1c...7284904a3fc93173e0d5a5d8e16a0bb2e7e32d49.patch?full_index=1";
            hash = "sha256-6ccvLCFXvDvUMynEGvQYGooLM2OgLuDWFwkldQj+1T4=";
          })
          (final.fetchpatch2 {
            name = "add-speed-hud.patch";
            url = "https://github.com/Sirius902/hlsdk-portable/compare/6ba528f2a36622a45c453f832934ab3adaca7c1c...9f354d92d0b5123246449ac95a1c751f3cb43f93.diff?full_index=1";
            hash = "sha256-p+0pt1DJFRHAOdgg16cxe2bXfykezCBDYtHgzYQWptM=";
          })
        ];

      postPatch =
        (prevAttrs.postPatch or "")
        + ''
          substituteInPlace pm_shared/pm_shared.c \
            --replace-fail "PM_PreventMegaBunnyJumping();" "(void)0;"
        '';
    });

    hlsdk-portable-opfor = prev.hlsdk-portable-opfor.overrideAttrs (prevAttrs: {
      # NOTE(Sirius902) Patch this away, not sure why this check is here. This
      # is not how the retail game behaves.
      postPatch =
        (prevAttrs.postPatch or "")
        + ''
          substituteInPlace dlls/gearbox/m249.cpp \
            --replace-fail "if (m_pPlayer->pev->flags & FL_ONGROUND)" "if (1)"
        '';
    });
  })

  (final: prev: let
    sdks = [
      final.hlsdk-portable
      final.hlsdk-portable-opfor
      final.hlsdk-portable-bshift
      final.hlsdk-portable-theyhunger
    ];
  in {
    xash3d-fwgs = prev.xash3d-fwgs.override {inherit sdks;};
    xash-dedicated = prev.xash-dedicated.override {inherit sdks;};
  })

  (final: prev: {
    poptracker = prev.poptracker.overrideAttrs (prevAttrs: {
      version = "0.35.1";
      src = prevAttrs.src.override {
        hash = "sha256-YPYGK1yDw0K5/gbJ9jwFSbpIJGKpkGy2iIcMiA9/xmA=";
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {};
        };
    });
  })

  (final: prev: {
    archipelago = prev.archipelago.overrideAttrs (finalAttrs: prevAttrs: {
      version = "0.6.7";
      src = final.fetchurl {
        url = "https://github.com/ArchipelagoMW/Archipelago/releases/download/${finalAttrs.version}/Archipelago_${finalAttrs.version}_linux-x86_64.AppImage";
        hash = "sha256-a5UazzqGu7q4Zg1AYHnbQjCTQNdcNaL/gZUjYV3Rk5Q=";
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {};
        };
    });
  })

  (final: prev: {
    n64recomp = prev.n64recomp.overrideAttrs (prevAttrs: {
      version = "0-unstable-2026-01-17";
      src = prevAttrs.src.override {
        tag = null;
        rev = "81213c1831fab2521a6a5459c67b63437d67e253";
        hash = "sha256-BfZTmKAXn+9b0lHg0SbTP4/ZTjk7IqvPc78ab8XNFoM=";
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version=branch"
              "--version-regex=(0-unstable-.*)"
            ];
          };
        };
    });
  })

  (final: prev: {
    z64decompress = prev.z64decompress.overrideAttrs (prevAttrs: {
      version = "1.0.3-unstable-2023-12-21";
      src = prevAttrs.src.override {
        tag = null;
        rev = "e2b3707271994a2a1b3afc6c3997a7cf6b479765";
        hash = "sha256-PHiOeEB9njJPsl6ScdoDVwJXGqOdIIJCZRbIXSieBIY=";
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version=branch"
              "--version-regex=v(.*)"
            ];
          };
        };
    });
  })

  (final: prev: {
    zelda64recomp = prev.zelda64recomp.overrideAttrs (prevAttrs: {
      version = "1.2.2-unstable-2025-12-29";
      src = prevAttrs.src.override {
        tag = null;
        rev = "ab677e76615e5e47b3b26c822ca426485752ac77";
        hash = "sha256-gL/PZTOuNInalIAZZYe/1tOKoMR0dTc8HBHPOuPBGtc=";
      };

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version=branch"
              "--version-regex=v(.*)"
            ];
          };
        };
    });
  })

  # TODO(Sirius902) Ugh I need to PR this...
  (final: prev: {
    bottles-unwrapped = prev.bottles-unwrapped.overrideAttrs (prevAttrs: {
      postPatch =
        (prevAttrs.postPatch or "")
        + ''
          substituteInPlace bottles/backend/utils/vulkan.py \
            --replace-fail '"vulkaninfo"' '"${final.vulkan-tools}/bin/vulkaninfo"'

          substituteInPlace bottles/fvs/repo.py \
            --replace-fail '"fvs2"' '"${final.fvs2}/bin/fvs2"'
        '';
    });
  })

  (final: prev: {
    zellij = prev.zellij.overrideAttrs (prevAttrs: {
      patches =
        (prevAttrs.patches or [])
        ++ [
          ../patches/zellij/0001-feat-pass-OSC-52-clipboard-read-through-to-host-term.patch
        ];

      passthru = removeAttrs (prevAttrs.passthru or {}) ["updateScript"];
    });
  })
]
