{inputs}: [
  (import ../pkgs/overlay.nix)
  (import ./moonlight/default.nix)

  inputs.nvim-conf.overlays.default

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

  # FUTURE(Sirius902) Disable fast math to fix blurriness on Wayland.
  # https://github.com/ValveSoftware/gamescope/issues/1622
  (final: prev: {
    gamescope = prev.gamescope.overrideAttrs (prevAttrs: {
      NIX_CFLAGS_COMPILE = (prevAttrs.NIX_CFLAGS_COMPILE or []) ++ ["-fno-fast-math"];
    });
  })

  (final: prev: {
    rpcs3 = prev.rpcs3.overrideAttrs (prevAttrs: {
      version = "0.0.39-unstable-2026-02-28";
      src = prevAttrs.src.override {
        tag = null;
        rev = "198c2e9eb835dbe95c674ad8c98138fb080f1ff4";
        hash = "sha256-h9r6yF7vxtcwSpPluELKSoeul4SZ/oXgvDARikdToHc=";
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
      version = "0.14.0-unstable-2026-02-24";

      src = prevAttrs.src.override {
        tag = null;
        rev = "e1ecd8e98c12128c6dca9044f6688dcec1b9cfc2";
        hash = "sha256-WNzf+BoOds3EFAuMf9Jb1rLQyvb2XxlHLxD7fV2iac8=";
      };

      patches = (prevAttrs.patches or []) ++ [../patches/shadps4/readbacks-perf-hack.patch];

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
        version = "0-unstable-2026-02-23";

        src = prevAttrs.src.override {
          tag = null;
          rev = "6c1ca0800249cf5841a31937c74fae8dcd837114";
          hash = "sha256-5v6kdiY9SHbEI4PQmtCkd7zef0f1NaaBRdmKkzdW0As=";
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
    }
  )

  (final: prev: {
    xash-sdk = prev.xash-sdk.overrideAttrs (prevAttrs: {
      patches = [
        (final.fetchpatch2 {
          name = "npc-door-panic.patch";
          url = "https://github.com/Sirius902/hlsdk-portable/commit/3edcc16cc1d312f56fd495c491e9cfa3a4851bdc.patch?full_index=1";
          hash = "sha256-bLvv4/A3/IYJAs9eA00zWV8m9t7BH/g6dKR9jIJ9koI=";
        })
      ];

      postPatch =
        (prevAttrs.postPatch or "")
        + ''
          substituteInPlace pm_shared/pm_shared.c \
            --replace-fail "PM_PreventMegaBunnyJumping();" "(void)0;"
        '';
    });
  })

  (final: prev: let
    sdks = [
      final.xash-sdk
      final.xash-sdk-opfor
      final.xash-sdk-bshift
      final.xash-sdk-theyhunger
    ];
  in {
    xash3d-fwgs = prev.xash3d-fwgs.override {inherit sdks;};
    xash-dedicated = prev.xash-dedicated.override {inherit sdks;};
  })

  # TODO(Sirius902) brokeded
  (final: prev: let
    version = "1.27.1";
  in {
    pure-prompt = assert prev.lib.assertMsg (prev.lib.versionOlder prev.pure-prompt.version version) "overlay no longer necessary";
      prev.pure-prompt.overrideAttrs (prevAttrs: {
        inherit version;
        src = prevAttrs.src.override {
          sha256 = "sha256-Fhk4nlVPS09oh0coLsBnjrKncQGE6cUEynzDO2Skiq8=";
        };
      });
  })

  # TODO(Sirius902) brokeded
  # https://github.com/NixOS/nixpkgs/issues/493431
  (final: prev: {
    lager = prev.lager.override {boost = final.boost188;};
  })
]
