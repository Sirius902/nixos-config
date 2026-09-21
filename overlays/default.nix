{inputs}: [
  # Merge repo-local maintainers into `lib.maintainers`. `lib` is an attribute
  # of the package set, so `callPackage` hands the extended one to every
  # `pkgs/*/package.nix` and entries read exactly as they would in nixpkgs.
  (_: prev: {
    lib = prev.lib.extend (_: libPrev: {
      maintainers = libPrev.maintainers // import ../maintainers/maintainer-list.nix;
    });
  })

  # `wrapForSteam pkg` re-exports a package with every `bin/` entry relaunched
  # through a fixed environment, so a Steam shortcut can point straight at it.
  # A launched process inherits the Steam runtime's loader, glibc-internal,
  # driver-discovery and toolkit-plugin variables, every one of them naming a
  # foreign closure; and a non-NixOS host has no `/run/opengl-driver`, the path
  # nixpkgs bakes into the GL and Vulkan dispatch libraries, leaving their
  # driver lookups nowhere to land. See docs/steam-deck.md.
  (final: _: {
    wrapForSteam = pkg: let
      inherit (final.lib) concatLists escapeShellArgs mapAttrsToList;
      inherit (final) mesa;

      # `ld.so` acts on the loader variables before the first line of a wrapper
      # script can clear them, so the script's own interpreter is already a
      # casualty: Steam preloads an overlay that links `libGL.so.1`, a Nix
      # loader does not resolve it, and an unresolvable dependency of a
      # preloaded object is fatal rather than skipped. A static executable has
      # no interpreter for `ld.so` to act on, which is what makes this the only
      # thing that can safely be the entry point.
      shim = final.writeText "wrap-for-steam.c" ''
        #include <stdio.h>
        #include <stdlib.h>
        #include <string.h>
        #include <unistd.h>

        int main(int argc, char **argv) {
          /* One compiled shim is hardlinked to every name, so the wrapper to
             exec is derived rather than baked in. /proc/self/exe resolves the
             whole symlink chain from the profile, landing beside the wrapper
             in the same store directory. */
          char self[4096];
          char target[4096];
          ssize_t len = readlink("/proc/self/exe", self, sizeof(self) - 1);
          if (len < 0) {
            perror("/proc/self/exe");
            return 127;
          }
          self[len] = '\0';

          char *slash = strrchr(self, '/');
          if (slash == NULL) {
            fprintf(stderr, "%s: not an absolute path\n", self);
            return 127;
          }
          *slash = '\0';
          if (snprintf(target, sizeof(target), "%s/.%s-env", self, slash + 1) >=
              (int)sizeof(target)) {
            fprintf(stderr, "%s: wrapper path too long\n", self);
            return 127;
          }

          unsetenv("LD_PRELOAD");
          unsetenv("LD_AUDIT");
          unsetenv("LD_LIBRARY_PATH");
          /* The kernel overwrites argv[0] with the script path when it runs a
             shebang, so carrying it across takes a variable. A multi-call
             binary like `nix` dispatches on it. */
          if (argc > 0) {
            setenv("WRAP_FOR_STEAM_ARGV0", argv[0], 1);
          }
          execv(target, argv);
          perror(target);
          return 127;
        }
      '';

      unset = [
        # Loader. Cleared once already by the shim, before this script's own
        # interpreter loaded; repeated here so the list stays one thing.
        "LD_PRELOAD"
        "LD_AUDIT"

        # pressure-vessel points these at its own SDL, which then replaces the
        # whole SDL ABI in-process.
        "SDL_DYNAMIC_API"
        "SDL3_DYNAMIC_API"

        # Private glibc module formats.
        "GCONV_PATH"
        "LOCPATH"

        # Driver discovery, superseded by the set below or wrong outright.
        "VK_ICD_FILENAMES"
        # Additive, so `VK_DRIVER_FILES` does not neutralise it.
        "VK_ADD_DRIVER_FILES"
        "VK_LAYER_PATH"
        "VK_ADD_LAYER_PATH"
        "VK_INSTANCE_LAYERS"
        "LIBGL_DRIVERS_PATH"
        "VDPAU_DRIVER_PATH"
        "GBM_BACKENDS_PATH"
        "__EGL_VENDOR_LIBRARY_DIRS"

        # Toolkit plugin trees.
        "GTK_PATH"
        "GTK_IM_MODULE_FILE"
        "GDK_PIXBUF_MODULE_FILE"
        "GIO_MODULE_DIR"
        "GIO_EXTRA_MODULES"
        "GSETTINGS_SCHEMA_DIR"
        "GST_PLUGIN_PATH"
        "GST_PLUGIN_PATH_1_0"
        "GST_PLUGIN_SYSTEM_PATH"
        "GST_PLUGIN_SYSTEM_PATH_1_0"
        "QT_PLUGIN_PATH"
        "QT_QPA_PLATFORM_PLUGIN_PATH"
        "QML_IMPORT_PATH"
        "QML2_IMPORT_PATH"

        # Interpreters and audio.
        "PYTHONPATH"
        "PYTHONHOME"
        "PERL5LIB"
        "PERLLIB"
        "ALSA_CONFIG_PATH"
        "ALSA_PLUGIN_DIR"
      ];

      set = {
        # The GLX vendor is a bare soname `dlopen` with no manifest to name it
        # by, so a search path is the only mechanism left; both JSON manifests
        # below carry absolute store paths, which is why nothing else needs one.
        LD_LIBRARY_PATH = "${mesa}/lib";
        __GLX_VENDOR_LIBRARY_NAME = "mesa";
        __EGL_VENDOR_LIBRARY_FILENAMES = "${mesa}/share/glvnd/egl_vendor.d/50_mesa.json";
        # One ICD rather than the directory: a directory also enumerates
        # lavapipe, putting a software device into `vkEnumeratePhysicalDevices`.
        VK_DRIVER_FILES = "${mesa}/share/vulkan/icd.d/radeon_icd.x86_64.json";
        LIBVA_DRIVERS_PATH = "${mesa}/lib/dri";
      };

      # Steam sources no login profile, so nothing has set these.
      setDefault = {
        LOCALE_ARCHIVE = "${final.glibcLocalesUtf8}/lib/locale/locale-archive";
        SSL_CERT_FILE = "${final.cacert}/etc/ssl/certs/ca-bundle.crt";
      };

      args =
        [
          "--run"
          "wrapForSteamArgv0=\${WRAP_FOR_STEAM_ARGV0-$0}; unset WRAP_FOR_STEAM_ARGV0"
          "--argv0"
          "$wrapForSteamArgv0"
        ]
        ++ concatLists (
          map (name: ["--unset" name]) unset
          ++ mapAttrsToList (name: value: ["--set" name value]) set
          ++ mapAttrsToList (name: value: ["--set-default" name value]) setDefault
        );
    in
      # The name has to survive unchanged, with only the hash to tell the two
      # apart: home-manager retires the previous profile by selecting the store
      # path that `endswith "home-manager-path"`, so a suffix here leaves the
      # old one installed and every later activation dies on the file conflict.
      final.runCommandCC pkg.name {
        nativeBuildInputs = [final.makeWrapper];
        buildInputs = [final.glibc.static];
        preferLocalBuild = true;
        allowSubstitutes = false;
        passthru = {unwrapped = pkg;};
        # An `outputsToInstall` naming outputs this derivation lacks breaks
        # every `buildEnv`; the rest of `meta` carries through, `priority`
        # included.
        meta = removeAttrs (pkg.meta or {}) ["outputsToInstall"];
      } ''
        shopt -s nullglob

        mkdir -p $out
        for entry in ${pkg}/*; do
          ln -s "$entry" "$out/$(basename "$entry")"
        done

        if [ -d ${pkg}/bin ]; then
          rm $out/bin
          mkdir $out/bin
          $CC -Os -static -o "$out/bin/.wrap-for-steam" ${shim}
          for exe in ${pkg}/bin/*; do
            name=$(basename "$exe")
            # A `bin/` entry that is not an executable file aborts makeWrapper,
            # and the error names the merged profile rather than the package it
            # came from.
            if [ ! -f "$exe" ] || [ ! -x "$exe" ]; then
              ln -s "$exe" "$out/bin/$name"
              continue
            fi
            makeWrapper "$exe" "$out/bin/.$name-env" ${escapeShellArgs args}
            ln "$out/bin/.wrap-for-steam" "$out/bin/$name"
          done
        fi
      '';
  })

  (import ../pkgs/overlay.nix)
  (import ./codex)
  (import ./claude-code)
  (import ./moonlight)

  inputs.nvim-conf.overlays.default

  (_: prev: {
    nix-update = prev.nix-update.overrideAttrs (prevAttrs: {
      patches =
        (prevAttrs.patches or [])
        ++ [
          # https://github.com/Mic92/nix-update/issues/327
          ../patches/nix-update/0001-resolve-flake-attributes-through-legacyPackages.patch
        ];
    });
  })

  (final: prev: {
    xwayland-satellite = prev.xwayland-satellite.overrideAttrs (prevAttrs: {
      patches =
        (prevAttrs.patches or [])
        ++ [
          # Stop focusing override-redirect popups, which X11 clients read as a
          # dismissal of their own menus.
          # https://github.com/Supreeeme/xwayland-satellite/pull/494
          (final.fetchpatch {
            name = "no-override-redirect-focus.patch";
            url = "https://github.com/Supreeeme/xwayland-satellite/commit/add2795134593faafce60e404a0a75df68e9ee0c.diff";
            hash = "sha256-/1zJYAIHC+xiVytHH5HDt83lZKLBGQQdAoS/y2ObTLc=";
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
  (_: prev: {
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
          ../patches/gamescope/add-window-cycle.patch
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
  (_: prev: {
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
      version = "0.0.42-unstable-2026-09-21";
      src = prevAttrs.src.override {
        tag = null;
        rev = "d08d568d5edf4f21508d9b8e471197e6d6f499ad";
        hash = "sha256-6FsI/iv0P45p4f55Z56BMg+GxuyQYZv5A/mjWMTWd44=";
      };

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
      version = "0.18.0-unstable-2026-09-21";

      src = prevAttrs.src.override {
        tag = null;
        rev = "00b0acaa561e1a694c1ad6f79276ac774461cb49";
        hash = "sha256-rUFJB1Vm3r+3v2d8XbCZ2UfIKJpScqkz7+SgQzaXRoc=";

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
            discord-rpc \
            freetype \
            glslang \
            hwinfo \
            imgui \
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
      version = "0-unstable-2026-09-12";

      src = prevAttrs.src.override {
        tag = null;
        rev = "4ce2f029c824fe3cb9dac80673b406baa6d22617";
        hash = "sha256-LJur1QDW4FJNvs6rYfSt6HZck5quuKQ6g46vJVyfsGU=";

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
            url = "https://github.com/FWGS/hlsdk-portable/compare/3ff784875a72b0b6f128a7b717e3949de64ce9f1...ea3ff3448769f57457284de973f07e086a5cf440.diff";
            hash = "sha256-r1YVZQM/oX2dNUDR9IS8A3vQiH7RnNXG50w6EOeuv3Q=";
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
      version = "2606a-unstable-2026-09-21";

      src = prevAttrs.src.override {
        tag = null;
        rev = "233b2dfe6d6427bed6874d641dfab04ccac2974e";
        hash = "sha256-20JsdH19FhZyFwtPUyXH5zJBl0Q5LC/D2XrH5Dhf6WU=";

        leaveDotGit = false;
        postFetch = ''
          echo 233b2dfe6d6427bed6874d641dfab04ccac2974e > $out/COMMIT
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
