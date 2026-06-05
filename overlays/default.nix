{inputs}: [
  (import ../pkgs/overlay.nix)
  (import ./moonlight)
  (import ./claude-code)

  inputs.nvim-conf.overlays.default

  (final: prev: {
    cosmic-comp = prev.cosmic-comp.overrideAttrs (prevAttrs: {
      patches =
        (prevAttrs.patches or [])
        ++ [
          # FUTURE(Sirius902) RDNA4 workaround: kind() delegation causes smithay to use
          # the hardware cursor plane, triggering a kernel bug where commit_minimal_transition_state
          # programs DCN cursor hardware with pitch=0.
          # https://gitlab.freedesktop.org/drm/amd/-/issues/4970
          # https://github.com/pop-os/cosmic-comp/issues/2361
          ../patches/cosmic-comp/default-kind.patch
          # FUTURE(Sirius902) Workaround for Wayland popups.
          # https://github.com/pop-os/cosmic-comp/pull/2243
          (final.fetchpatch2 {
            name = "remove-popup-serial-check.patch";
            url = "https://github.com/pop-os/cosmic-comp/commit/e334a29cc2a3bae0b13cd4668a22a72ea20a9229.patch?full_index=1";
            hash = "sha256-6hI12eWay6L4DZcJxcmJK/nMi71qTqaWtLrxOuhaYtA=";
          })
        ];
    });
  })

  # FUTURE(Sirius902) https://github.com/cosmic-utils/clipboard-manager/pull/207
  (final: prev: {
    cosmic-ext-applet-clipboard-manager = prev.cosmic-ext-applet-clipboard-manager.overrideAttrs (finalAttrs: prevAttrs: {
      version = "0-unstable-2026-03-24";
      src = prevAttrs.src.override {
        rev = "d473e8f09e8bc2289a76707898063a13714c79dc";
        hash = "sha256-RNRSShrT7wS4GmQNd3tXtT8G/4qLM9zxntXgBQ6C7ps=";
      };
      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname version src;
        hash = "sha256-+yqFV8HdPjkVny+6FKkZFEQAq1rwe7JXmoTJ7zge8bg=";
      };

      patches =
        (prevAttrs.patches or [])
        ++ [
          (final.fetchpatch2 {
            name = "fix-clipboard-freeze.patch";
            url = "https://github.com/cosmic-utils/clipboard-manager/compare/d473e8f09e8bc2289a76707898063a13714c79dc...5cf8419b5043055acfef201f5f52669cd293846d.diff?full_index=1";
            hash = "sha256-y7ZBV7KNX6zdHsA6AW8/4NlUbaYGfAP7QOaINP5FSQo=";
          })
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

  (final: prev: {
    gamescope = prev.gamescope.overrideAttrs (prevAttrs: {
      patches =
        (prevAttrs.patches or [])
        ++ [
          (final.fetchpatch2 {
            name = "add-window-cycle.patch";
            url = "https://github.com/Sirius902/gamescope/commit/9d6513068846f1b9fea5afc326fc9d2758079fdb.patch?full_index=1";
            hash = "sha256-yNu7axkkgilokv5qjmZdr5HcTOkQ9AE5tUkb7QcRHbk=";
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

  # FUTURE(Sirius902) mangoapp: stop unmap/remap on HUD toggle to prevent focus loss.
  (final: prev: {
    mangohud = prev.mangohud.overrideAttrs (prevAttrs: {
      patches =
        (prevAttrs.patches or [])
        ++ [
          ../patches/mangohud/mangoapp-no-hide-window.patch
        ];
    });
  })

  (final: prev: {
    rpcs3 = prev.rpcs3.overrideAttrs (prevAttrs: {
      version = "0.0.41-unstable-2026-06-05";
      src = prevAttrs.src.override {
        tag = null;
        rev = "4a92d96cf4d6942a560ea815020d94a2ca1bc4f4";
        hash = "sha256-emqRg0dWLoq4HpQZvjKs92BSGvkv1BWlv8Yiq4S0t9w=";
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
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version=branch"
              "--version-regex=v(\\d+\\.\\d+\\.\\d+.*)"
            ];
          };
        };
    });
  })

  (final: prev: {
    shadps4 = prev.shadps4.overrideAttrs (finalAttrs: prevAttrs: {
      version = "0.16.0-unstable-2026-06-03";

      src = prevAttrs.src.override {
        tag = null;
        rev = "6c282aa1da11cd657aec8fef02d46c3940dc1beb";
        hash = "sha256-IkE8rxL8QqeM6im8g4bUIT4Ezq/Cv97ZdpSG61+GelU=";

        postCheckout = ''
          cd "$out"

          git rev-parse --short=8 HEAD > $out/COMMIT
          date -u -d "@$(git log -1 --pretty=%ct)" "+%Y-%m-%dT%H:%M:%SZ" > $out/SOURCE_DATE_EPOCH

          git -C externals submodule update --init --depth 1 \
            ImGuiFileDialog \
            LibAtrac9 \
            aacdec/fdk-aac \
            cpp-httplib \
            dear_imgui \
            discord-rpc \
            glslang \
            hwinfo \
            libressl \
            libusb \
            minimp3 \
            sirit \
            spdlog \
            tracy \
            zydis
          git -C externals/sirit submodule update --init --depth 1 externals/SPIRV-Headers
          git -C externals/zydis submodule update --init --depth 1 dependencies/zycore
        '';
      };

      postPatch = ''
        substituteInPlace src/common/scm_rev.cpp.in \
          --replace-fail @APP_VERSION@ ${finalAttrs.version} \
          --replace-fail @GIT_REV@ $(cat COMMIT) \
          --replace-fail @GIT_BRANCH@ ${finalAttrs.version} \
          --replace-fail @GIT_DESC@ nixpkgs \
          --replace-fail @BUILD_DATE@ $(cat SOURCE_DATE_EPOCH)
      '';

      cmakeFlags =
        (prevAttrs.cmakeFlags or [])
        ++ [
          (final.lib.cmakeBool "SPDLOG_FMT_EXTERNAL" true)
        ];

      buildInputs =
        (prevAttrs.buildInputs or [])
        ++ [
          final.glslang
          final.openal-soft
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

    shadps4-qtlauncher = prev.shadps4-qtlauncher.overrideAttrs (finalAttrs: prevAttrs: {
      version = "0-unstable-2026-06-04";

      src = prevAttrs.src.override {
        tag = null;
        rev = "f57cd3051a456b125013c782b46a9cdd3c75a5e0";
        hash = "sha256-9LekGvM/zNwxMvlQQlgbOlvSnCBmt6kh0Bj5/9N2YDQ=";

        postCheckout = ''
          cd "$out"

          git rev-parse --short=8 HEAD > $out/COMMIT
          date -u -d "@$(git log -1 --pretty=%ct)" "+%Y-%m-%dT%H:%M:%SZ" > $out/SOURCE_DATE_EPOCH

          git -C externals submodule update --init --depth 1 \
            json \
            spdlog \
            volk
        '';
      };

      postPatch = ''
        substituteInPlace src/common/scm_rev.cpp.in \
          --replace-fail @APP_VERSION@ ${finalAttrs.version} \
          --replace-fail @GIT_REV@ $(cat COMMIT) \
          --replace-fail @GIT_BRANCH@ ${finalAttrs.version} \
          --replace-fail @GIT_DESC@ nixpkgs \
          --replace-fail @BUILD_DATE@ $(cat SOURCE_DATE_EPOCH)

        substituteInPlace src/common/versions.cpp \
          --replace-fail "@shadps4-qt@" "$out"

        substituteInPlace src/qt_gui/gui_settings.cpp \
          --replace-fail "@shadps4-qt@" "$out"

        substituteInPlace src/qt_gui/version_dialog.cpp \
          --replace-fail "@shadps4-qt@" "$out"
      '';

      cmakeFlags =
        (prevAttrs.cmakeFlags or [])
        ++ [
          (final.lib.cmakeBool "SPDLOG_FMT_EXTERNAL" true)
        ];

      buildInputs =
        (prevAttrs.buildInputs or [])
        ++ [
          final.openal-soft
        ];

      patches =
        builtins.filter
        (p: !final.lib.hasSuffix "version-directory.patch" (baseNameOf (toString p)))
        prevAttrs.patches;

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
    hlsdk-portable = prev.hlsdk-portable.overrideAttrs (prevAttrs: {
      patches =
        (prevAttrs.patches or [])
        ++ [
          (final.fetchpatch2 {
            name = "npc-door-panic.patch";
            url = "https://github.com/Sirius902/hlsdk-portable/compare/6ba528f2a36622a45c453f832934ab3adaca7c1c...7284904a3fc93173e0d5a5d8e16a0bb2e7e32d49.patch?full_index=1";
            hash = "sha256-N2JYSVrsOBwm0ep1Wlh8/3FWZbhL84CXOFgaXL01dVw=";
          })
          (final.fetchpatch2 {
            name = "add-speed-hud.patch";
            url = "https://github.com/Sirius902/hlsdk-portable/compare/6ba528f2a36622a45c453f832934ab3adaca7c1c...9f354d92d0b5123246449ac95a1c751f3cb43f93.diff?full_index=1";
            hash = "sha256-Z8leyEG7/gZ/Ux73n2UYJH775EWr4IHVR7TGrAy8hRM=";
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
          updateScript = final.nix-update-script {
            extraArgs = ["--version-regex=v([0-9.]+(-rc[0-9]+)?)"];
          };
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
      version = "0-unstable-2026-05-27";
      src = prevAttrs.src.override {
        tag = null;
        rev = "ffb39cdad1da5de07eaaa48bd1db4a89a7986771";
        hash = "sha256-/MmRvLWxh/uaFXp0eiNdrnMKrrYQvjxmw/+/o5lXyFU=";
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
      version = "1.2.2-unstable-2026-05-17";
      src = prevAttrs.src.override {
        tag = null;
        rev = "1a9c26613c6e0906140dc8bcca7362cbe00bf1eb";
        hash = "sha256-tx+xBwqp+onksivFnM1uMtO3IhsgKbJl5aO1ahH+w3c=";
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

  # FUTURE(Sirius902) openldap has evil tests
  # https://github.com/NixOS/nixpkgs/issues/440594
  # I guess hydra doesn't have openldap cached for i686-linux so it has to
  # build from source for bottles...
  (final: prev: {
    bottles = prev.bottles.override {
      buildFHSEnv = fhsArgs: let
        patchPkgs = pkgs:
          pkgs
          // {
            openldap = pkgs.openldap.overrideAttrs {doCheck = false;};
          };
      in
        prev.buildFHSEnv (fhsArgs
          // {
            targetPkgs = pkgs: (fhsArgs.targetPkgs or (_: [])) (patchPkgs pkgs);
            multiPkgs = pkgs: (fhsArgs.multiPkgs or (_: [])) (patchPkgs pkgs);
          });
    };
  })

  (final: prev: {
    zellij = prev.zellij.overrideAttrs (prevAttrs: {
      patches =
        (prevAttrs.patches or [])
        ++ [
          ../patches/zellij/0001-feat-pass-OSC-52-clipboard-read-through-to-host-term.patch
        ];
    });
  })

  (final: prev: {
    dolphin-emu = prev.dolphin-emu.overrideAttrs (prevAttrs: {
      version = "2603a-unstable-2026-06-04";

      src = prevAttrs.src.override {
        tag = null;
        rev = "aabea5b1e3f13177aa302f99b435a70ad6a9b0b1";
        hash = "sha256-1JCeDt7mEhZAXyp2AERl+VpQ7FYjb90BSeo8hGo1gdw=";

        leaveDotGit = false;
        postFetch = ''
          echo aabea5b1e3f13177aa302f99b435a70ad6a9b0b1 > $out/COMMIT
        '';
      };

      # Allow Archipelago's dolphin-memory-engine to read Dolphin's memory
      # via process_vm_readv despite ptrace_scope=1.
      qtWrapperArgs =
        (prevAttrs.qtWrapperArgs or [])
        ++ (let
          allowPtrace = final.stdenv.mkDerivation {
            name = "allow-ptrace";
            dontUnpack = true;
            installPhase = ''
              mkdir -p $out/lib
              $CC -shared -fPIC -o $out/lib/allow-ptrace.so -x c - <<'CSRC'
              #include <sys/prctl.h>
              __attribute__((constructor))
              static void allow_ptrace(void) {
                prctl(0x59616d61, -1L, 0, 0, 0);
              }
              CSRC
            '';
          };
        in [
          "--prefix LD_PRELOAD : ${allowPtrace}/lib/allow-ptrace.so"
        ]);

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version=branch"
              "--version-regex=([0-9]+[a-z]+-unstable-.*)"
            ];
          };
        };
    });
  })

  (final: prev: {
    dusklight-rando = prev.dusklight.overrideAttrs (prevAttrs: {
      version = "0-unstable-2026-06-05";
      src = prevAttrs.src.override {
        rev = "1868d698f58329385a37062f4612e64e0c06c78f";
        hash = "sha256-1akzzF/D17xZ1eMn8TOgEWD6dsa9Xyo6G+bSVxuqj80=";
      };

      # FUTURE(Sirius902) Every thread, including the numerous mesa threads, will get
      # this buffer and crash. Mark this as `static` instead and hope it's safe until
      # it's addressed upstream.
      postPatch =
        (prevAttrs.postPatch or "")
        + ''
          substituteInPlace src/dusk/randomizer/generator/utility/thread_local.hpp \
            --replace-fail "inline static thread_local T data;" "inline static T data;"

          substituteInPlace extern/aurora/lib/dolphin/card.cpp \
            --replace-fail 'return "USA";' 'return "USA-rando";' \
            --replace-fail 'return "EUR";' 'return "EUR-rando";' \
            --replace-fail 'return "JAP";' 'return "JAP-rando";'
        '';

      preConfigure =
        (prevAttrs.preConfigure or "")
        + ''
          cp -r --no-preserve=mode ${
            final.fetchFromGitHub {
              owner = "matheusgomes28";
              repo = "base64pp";
              rev = "v0.2.0-rc0";
              hash = "sha256-DYdnjbdZmQFOizg2SwAu35kWA0F72tE6ywe00azlqxk=";
            }
          } base64pp-src
          cmakeFlagsArray+=("-DFETCHCONTENT_SOURCE_DIR_BASE64PP=$PWD/base64pp-src")
        '';

      cmakeFlags =
        prevAttrs.cmakeFlags
        ++ [
          (prev.lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_YAML-CPP" "${
            final.fetchFromGitHub {
              owner = "jbeder";
              repo = "yaml-cpp";
              rev = "yaml-cpp-0.9.0";
              hash = "sha256-+FOsPQY44h1g9tEw3O281LkiYKXdW2jnFKw+oTRkhGw=";
            }
          }")
          (prev.lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_BATTERY-EMBED" "${
            final.fetchFromGitHub {
              owner = "batterycenter";
              repo = "embed";
              rev = "fdbae3f";
              hash = "sha256-yCLADGd8VITzIWr3aEt+jrzUDAKTk3YljNOuToK1zio=";
            }
          }")
        ];

      postInstall =
        (prevAttrs.postInstall or "")
        + final.lib.optionalString final.stdenv.hostPlatform.isLinux ''
          mv $out/share/applications/dev.twilitrealm.dusk.desktop \
           $out/share/applications/dev.twilitrealm.dusk-rando.desktop

          for f in $out/share/icons/hicolor/*/apps/dusk.png; do
            mv "$f" "''${f%dusk.png}dusk-rando.png"
          done

          substituteInPlace $out/share/applications/dev.twilitrealm.dusk-rando.desktop \
            --replace-fail "Name=Dusklight" "Name=Dusklight Randomizer" \
            --replace-fail "GenericName=Dusklight" "GenericName=Dusklight Randomizer" \
            --replace-fail "Icon=dev.twilitrealm.dusk" "Icon=dev.twilitrealm.dusk-rando"
        ''
        + final.lib.optionalString final.stdenv.hostPlatform.isDarwin ''
          mv $out/Applications/Dusklight.app $out/Applications/DusklightRandomizer.app
        '';

      passthru =
        (prevAttrs.passthru or {})
        // {
          updateScript = final.nix-update-script {
            extraArgs = [
              "--version=branch=randomizer"
              "--version-regex=(0-unstable-.*)"
            ];
          };
        };
    });
  })
]
