{inputs}: [
  # Merge repo-local maintainers into `lib.maintainers`. `lib` is an attribute
  # of the package set, so `callPackage` hands the extended one to every
  # `pkgs/*/package.nix` and entries read exactly as they would in nixpkgs.
  (_: prev: {
    lib = prev.lib.extend (_: libPrev: {
      maintainers = libPrev.maintainers // import ../maintainers/maintainer-list.nix;
    });
  })

  # `checkOutputLayout pkg` builds the docs/package-layout.md check for a
  # package, wired up as `passthru.tests.layout` on everything in
  # `pkgs/all-packages.nix`. It walks the built `$out` instead of the
  # expression, so a directory named by a `--destdir` flag, by a path in
  # another file, or by a shell variable is covered the same as a literal.
  (final: _: {
    checkOutputLayout = pkg: let
      inherit (final.lib) concatStringsSep optionals;
      inherit (final.stdenv.hostPlatform) isDarwin;

      # The standard prefixes. A darwin app bundle adds one tree of its own.
      prefixes =
        ["bin" "etc" "include" "lib" "libexec" "nix-support" "sbin" "share"]
        ++ optionals isDarwin ["Applications"];

      # Trees whose whole point is to merge across packages: freedesktop
      # metadata, and the plugin directories a host application owns. Darwin
      # adds the two bundle directories cmake installs beside the prefix.
      sharedInShare =
        [
          "applications"
          "doc"
          "icons"
          "licenses"
          "man"
          "metainfo"
          "nautilus-python"
          "pixmaps"
        ]
        ++ optionals isDarwin ["MacOS" "Resources"];
      sharedInLib = ["ghidra" "udev"];
    in
      final.runCommandLocal "${pkg.pname}-layout-check" {} ''
        shopt -s nullglob

        root=${pkg}
        pname=${pkg.pname}
        status=0

        fail() {
          echo "error: $1" >&2
          status=1
        }

        # Every entry of the directory named in $1 is either the package's own
        # $pname directory or one of the shared trees passed after the hint.
        check_entries() {
          local dir="$1" hint="$2" entry name
          shift 2
          for entry in "$root/$dir"/*; do
            name=$(basename "$entry")
            case " $pname $* " in
            *" $name "*) continue ;;
            esac
            fail "$dir/$name: $hint"
          done
        }

        for entry in "$root"/*; do
          name=$(basename "$entry")
          case " ${concatStringsSep " " prefixes} " in
          *" $name "*) continue ;;
          esac
          fail "$name: the top level takes only the standard prefixes"
        done

        check_entries share "app-private data goes in share/$pname" \
          ${concatStringsSep " " sharedInShare}
        check_entries lib "app-private files go in lib/$pname" \
          ${concatStringsSep " " sharedInLib}

        for entry in "$root"/share/licenses/*; do
          name=$(basename "$entry")
          if [ "$name" != "$pname" ]; then
            fail "share/licenses/$name: licenses go in share/licenses/$pname"
          fi
        done

        for entry in "$root"/bin/*; do
          if [ -d "$entry" ]; then
            fail "bin/$(basename "$entry"): bin holds executables, not directories"
          fi
        done

        if [ "$status" -ne 0 ]; then
          echo "in $root" >&2
          echo "see docs/package-layout.md" >&2
          exit 1
        fi

        touch $out
      '';
  })

  (import ../pkgs/overlay.nix)
  (import ./codex)
  (import ./claude-code)
  (import ./moonlight)

  inputs.nvim-conf.overlays.default

  (final: prev: {
    niri = prev.niri.overrideAttrs (prevAttrs: {
      patches =
        (prevAttrs.patches or [])
        ++ [
          # FUTURE(Sirius902) Add SHM screencast fallback so Discord/Electron
          # consumers that don't accept dmabuf modifiers can negotiate a format.
          # https://github.com/niri-wm/niri/pull/1791 (fixes #455)
          (final.fetchpatch {
            name = "niri-pr-1791-shm-sharing.patch";
            url = "https://github.com/niri-wm/niri/compare/8ed0da44d974c32c6877d2f4630c314da0717ecb...2ab59b90d55afbbe362a63e2a061afe4b524d8c4.diff";
            hash = "sha256-q7rRmWgplPWAy/LDAbuSiuL+xTdCaPDx3DryZ3f+fqg=";
          })
        ];
    });
  })

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
          (final.fetchpatch {
            name = "remove-popup-serial-check.patch";
            url = "https://github.com/pop-os/cosmic-comp/commit/e334a29cc2a3bae0b13cd4668a22a72ea20a9229.diff";
            hash = "sha256-kEKoS4eG1KsEAjCdyrPixkS3NjS+XPjmfEuhJ/ukrsQ=";
          })
        ];
    });
  })

  # FUTURE(Sirius902) https://github.com/cosmic-utils/clipboard-manager/pull/207
  (final: prev: {
    cosmic-ext-applet-clipboard-manager = prev.cosmic-ext-applet-clipboard-manager.overrideAttrs (finalAttrs: prevAttrs: {
      version = "0-unstable-2026-08-03";
      src = prevAttrs.src.override {
        rev = "25e2dfde02ab82f58fe184bb8f3394465e99dc88";
        hash = "sha256-XyJwW+yXhrTl6dYsIBBLE29J9ecmuhOBGYv6H+GVVtU=";
      };
      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname version src;
        hash = "sha256-ABo4fAtFCaIyNukOUZqHpBhR0fANkb/h7lz755LyRpA=";
      };

      patches =
        (prevAttrs.patches or [])
        ++ [
          ../patches/clipboard-manager/fix-clipboard-freeze.patch
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
        shipwright = "$out/share/shipwright/soh.elf";
        shipwright_stable = "$out/share/shipwright-stable/soh.elf";
        shipwright-ap = "$out/share/shipwright-ap/soh.elf";
        _2ship2harkinian = "$out/share/2ship2harkinian/2s2h.elf";
        zelda64recomp = "$out/bin/Zelda64Recompiled";
      }
    else if prev.stdenv.hostPlatform.isDarwin
    then
      # On Darwin the hidapi driver isn't usable without entitlements so just treat it as a regular controller and init hid via a separate program.
      prev.lib.genAttrs ["shipwright" "shipwright_stable" "shipwright-ap" "_2ship2harkinian"] (
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

  # glfw3-minecraft backs prismlauncher's "Use system installation of GLFW"
  # tweak. GLFW 3.4 (release) aborts the whole game with SIGABRT the instant a
  # file is dragged onto the window on Wayland: its wl_data_offer listener wires
  # up only the `offer` event, leaving the v3 source_actions/action handlers
  # NULL, so libwayland-client wl_abort()s on the first drag event.
  # https://github.com/glfw/glfw/issues/2835
  (final: prev: {
    glfw3-minecraft = prev.glfw3-minecraft.overrideAttrs (prevAttrs: {
      patches =
        (prevAttrs.patches or [])
        ++ [
          ../patches/glfw3-minecraft/0001-wayland-fix-drag-and-drop-crash.patch
        ];
    });
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
          (final.fetchpatch {
            name = "add-window-cycle.patch";
            url = "https://github.com/ValveSoftware/gamescope/commit/9d6513068846f1b9fea5afc326fc9d2758079fdb.diff";
            hash = "sha256-hy1ZDR/k9TIAGmN2yD5PUI0/4JjlYKmaRUwuvhhMN8w=";
          })
          ../patches/gamescope/0001-main-Strip-gameoverlayrenderer.so-from-gamescope-s-o.patch
          (final.fetchpatch {
            name = "clamp-cursor-adaptive-sync.patch";
            url = "https://github.com/ValveSoftware/gamescope/commit/2b18c4eee02bc8600ce11705cada906e6bbe8232.diff";
            hash = "sha256-w3ucV7GUi/oyIRd1MBeJqeJhhmwDSFsGzdSU0N0+M7A=";
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
      version = "0.0.42-unstable-2026-08-29";
      src = prevAttrs.src.override {
        tag = null;
        rev = "eb61fc1fbd6623c32edd10b9403775656fec1b90";
        hash = "sha256-HwKZpTrslqBVHLqwWl9J+F2vfWsjeJmGgQUlH8mW+88=";
      };

      patches =
        builtins.filter
        (p: !final.lib.hasSuffix "ffmpeg-9-pix-fmts.patch" (baseNameOf (toString p)))
        prevAttrs.patches;

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
      version = "0.18.0-unstable-2026-08-27";

      src = prevAttrs.src.override {
        tag = null;
        rev = "388cff5177f82e75a667d529212d34f3c255b7fc";
        hash = "sha256-KIPIF7CK5c2yOy7MQlUaHThEWAMjd3XNFsUM9vETC9I=";

        postCheckout = ''
          cd "$out"

          git rev-parse --short=8 HEAD > $out/COMMIT
          date -u -d "@$(git log -1 --pretty=%ct)" "+%Y-%m-%dT%H:%M:%SZ" > $out/SOURCE_DATE_EPOCH

          git -C externals submodule update --init --depth 1 \
            ImGuiFileDialog \
            LibAtrac9 \
            aacdec/fdk-aac \
            abseil-cpp \
            cpp-httplib \
            dear_imgui \
            discord-rpc \
            freetype \
            glslang \
            hwinfo \
            libressl \
            libusb \
            minimp3 \
            miniupnp \
            protobuf \
            sirit \
            spdlog \
            tracy \
            zarchive \
            zstd \
            zydis
          git -C externals/sirit submodule update --init --depth 1 externals/SPIRV-Headers
          git -C externals/zydis submodule update --init --depth 1 dependencies/zycore
        '';
      };

      patches = [];

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
          (final.lib.cmakeBool "ENABLE_SYSTEM_LIBRARIES" true)
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
      version = "0-unstable-2026-08-26";

      src = prevAttrs.src.override {
        tag = null;
        rev = "d2c682c01cbea32abe57a6dda2cd8404ba503f15";
        hash = "sha256-rB+pxDx80iPd6vhqumb0y+EddHc6M2Nga4rrg5QFrx8=";

        postCheckout = ''
          cd "$out"

          git rev-parse --short=8 HEAD > $out/COMMIT
          date -u -d "@$(git log -1 --pretty=%ct)" "+%Y-%m-%dT%H:%M:%SZ" > $out/SOURCE_DATE_EPOCH

          git -C externals submodule update --init --depth 1 \
            json \
            spdlog \
            volk \
            zarchive \
            zstd
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
          (final.fetchpatch {
            name = "npc-door-panic.patch";
            url = "https://github.com/FWGS/hlsdk-portable/compare/6ba528f2a36622a45c453f832934ab3adaca7c1c...7284904a3fc93173e0d5a5d8e16a0bb2e7e32d49.diff";
            hash = "sha256-gMjqvBEMK7gItyE5wmCq/RjOMLdzItZSKQqQS9o1a6w=";
          })
          (final.fetchpatch {
            name = "add-speed-hud.patch";
            url = "https://github.com/FWGS/hlsdk-portable/compare/6ba528f2a36622a45c453f832934ab3adaca7c1c...9f354d92d0b5123246449ac95a1c751f3cb43f93.diff";
            hash = "sha256-7Hsg9NtBejtj1BJPwuMYPryhj+lyXVgO+syTzn5SvGM=";
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
      version = "0.35.4";
      src = prevAttrs.src.override {
        hash = "sha256-ilnBVwzd/tdolchgjz5EsMou7fMWT0xU/gTC+HBnDjU=";
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

  (final: prev: {
    dolphin-emu = prev.dolphin-emu.overrideAttrs (prevAttrs: {
      version = "2606a-unstable-2026-08-29";

      src = prevAttrs.src.override {
        tag = null;
        rev = "5508158a7743e1c0c56540ba08d0851b2afdf537";
        hash = "sha256-lFa5HKRWk5AbvhyYZdVIeYceelNAvYP2AH7+H8XEWoQ=";

        leaveDotGit = false;
        postFetch = ''
          echo 5508158a7743e1c0c56540ba08d0851b2afdf537 > $out/COMMIT
        '';
      };

      # Allow Archipelago's dolphin-memory-engine to read Dolphin's memory
      # via process_vm_readv despite ptrace_scope=1.
      qtWrapperArgs =
        (prevAttrs.qtWrapperArgs or [])
        ++ final.lib.optionals final.stdenv.hostPlatform.isLinux (let
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
]
