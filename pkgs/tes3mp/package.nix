{
  lib,
  stdenv,
  callPackage,
  fetchFromGitHub,
  fetchpatch,
  cmake,
  pkg-config,
  makeBinaryWrapper,
  copyDesktopItems,
  makeDesktopItem,
  libsForQt5,
  SDL2,
  boost,
  bullet,
  ffmpeg_6,
  libGL,
  libxt,
  luajit,
  lz4,
  mygui,
  openal,
  openscenegraph,
  unshield,
  nix-update-script,
  # Options
  buildServer ? false,
  crabnet ? callPackage ./crabnet.nix {},
}:
stdenv.mkDerivation (finalAttrs: let
  # NOTE(Sirius902) Identical to nixpkgs' openmw's, so both come from its
  # binary cache.
  osg' = (openscenegraph.override {colladaSupport = true;}).overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [])
      ++ [
        (fetchpatch {
          # Darwin: Without this patch, OSG won't build osgdb_png.so, which is required by OpenMW.
          name = "darwin-osg-plugins-fix.patch";
          url = "https://gitlab.com/OpenMW/openmw-dep/-/raw/1305497c009dc0e7a6a70fe14f0a2f92b96cbcb4/macos/osg.patch";
          hash = "sha256-G8Y+fnR6FRGxECWrei/Ixch3A3PkRfH6b5q9iawsSCY=";
        })
      ];
    cmakeFlags =
      (oldAttrs.cmakeFlags or [])
      ++ [
        "-Wno-dev"
        (lib.cmakeFeature "OpenGL_GL_PREFERENCE" "GLVND")
        (lib.cmakeBool "BUILD_OSG_PLUGINS_BY_DEFAULT" false)
        (lib.cmakeBool "BUILD_OSG_DEPRECATED_SERIALIZERS" false)
      ]
      ++ (map (plugin: lib.cmakeBool "BUILD_OSG_PLUGIN_${plugin}" true) [
        "BMP"
        "DAE"
        "DDS"
        "FREETYPE"
        "JPEG"
        "OSG"
        "PNG"
        "TGA"
      ]);
  });

  bullet' = bullet.overrideAttrs (oldAttrs: {
    cmakeFlags =
      (oldAttrs.cmakeFlags or [])
      ++ [
        "-Wno-dev"
        (lib.cmakeFeature "OpenGL_GL_PREFERENCE" "GLVND")
        (lib.cmakeBool "USE_DOUBLE_PRECISION" true)
        (lib.cmakeBool "BULLET2_MULTITHREADING" true)
      ];
  });

  # 0.47 overrides DataManager::getDataPath as declared before 3.4.3, and its
  # layouts still use obsolete properties
  # (https://gitlab.com/OpenMW/openmw/-/issues/5896).
  mygui' = mygui.overrideAttrs (prevAttrs: {
    version = "3.4.2";
    src = fetchFromGitHub {
      owner = "MyGUI";
      repo = "mygui";
      tag = "MyGUI3.4.2";
      hash = "sha256-yBV0ImOFJlqBPqqOjXYe4SFO2liSGZCEwvehED5Ubj4=";
    };
    patches = [];
    cmakeFlags =
      prevAttrs.cmakeFlags
      ++ [
        (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.10")
        (lib.cmakeBool "MYGUI_DONT_USE_OBSOLETE" false)
      ];
  });

  # CoreScripts sets decode_null_as_lightuserdata, which only TES3MP's fork has.
  lua-cjson' = luajit.pkgs.lua-cjson.overrideAttrs {
    version = "2.1.0.7-unstable-2019-04-14";
    src = fetchFromGitHub {
      owner = "TES3MP";
      repo = "lua-cjson";
      rev = "c3abdb769ffd88c74d8c421d49af9f5d2c8cf845";
      hash = "sha256-kMlxa93zhE8ZDg51aeGp+uiJgu7ocQvYBDEIRlLLhmo=";
    };
  };

  recast = fetchFromGitHub {
    owner = "recastnavigation";
    repo = "recastnavigation";
    rev = "e75adf86f91eb3082220085e42dda62679f9a3ea";
    hash = "sha256-HvVpxUDSy7KfiHJ/uOjgAVSGT0gxlPt5gagbxqhZcZo=";
  };
in {
  pname = "tes3mp";
  version = "0.8.1";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "TES3MP";
    repo = "TES3MP";
    tag = "tes3mp-${finalAttrs.version}";
    hash = "sha256-kLTI51jQAn/G/ffNlF3YaMPRbFagBNUmckH82jex/pE=";
    leaveDotGit = true;
    postFetch = ''
      cd $out
      git rev-parse HEAD > COMMIT
      rm -rf .git
    '';
  };

  patches =
    [
      # Include <cstdint> for GCC 13 https://github.com/TES3MP/TES3MP/pull/674
      (fetchpatch {
        name = "include-cstdint.patch";
        url = "https://github.com/TES3MP/TES3MP/commit/7921f71a79e96f817a2009100e5105a7948b3fe2.diff";
        hash = "sha256-mpxuOSPA2xixgBeYXsxutEUI7VJL5PxAeZgaNU7YkJQ=";
      })
      # Add missing includes and a cast for GCC 14 https://github.com/TES3MP/TES3MP/pull/691
      (fetchpatch {
        name = "gcc-14-includes-and-cast.patch";
        url = "https://github.com/TES3MP/TES3MP/commit/a877ccd5d2f6d49be9f2a5a5c458910e850ed47c.diff";
        hash = "sha256-l3kcqBoKKv5SsR2t4Ib/1qEYLF+GmBKh3Zxq2WgDoyw=";
      })
      ./0001-Drop-the-void-cast-from-GCC-s-constexpr-constructor.patch
      ./0002-Include-algorithm-in-filesystemarchive.cpp.patch
    ]
    ++ lib.optionals (!buildServer) [
      # Signal EOF to FFmpeg 5+ from the sound decoder instead of hanging https://gitlab.com/OpenMW/openmw/-/merge_requests/1941
      (fetchpatch {
        name = "ffmpeg-decoder-signal-eof.patch";
        url = "https://github.com/OpenMW/openmw/commit/c5cdb0c27797281dfde72761baf2cc6554a86189.diff";
        excludes = ["CHANGELOG.md"];
        hash = "sha256-QROpvFwDYkjbLq4NbRT4LxV0jdefWWTonEn/3Ui+hIY=";
      })
      # Signal EOF to FFmpeg 5+ from the video player https://gitlab.com/OpenMW/openmw/-/merge_requests/4378
      (fetchpatch {
        name = "videoplayer-signal-eof.patch";
        url = "https://github.com/OpenMW/openmw/commit/2dcf1f7ed2601672e4081b6318334968fd7a9b68.diff";
        hash = "sha256-+gV2FpoZ69V5bodTIY6pQhzfdspHNKBdlZd3b8EYH2w=";
      })
    ];

  postPatch = ''
    # NOTE(Sirius902) Clients and servers only connect when these hashes match.
    substituteInPlace files/version.in \
      --replace-fail '@OPENMW_VERSION_COMMITHASH@' "$(cat COMMIT)"

    substituteInPlace components/files/configurationmanager.cpp \
      --replace-fail 'applicationName = "openmw";' 'applicationName = "tes3mp";'
    substituteInPlace files/org.openmw.launcher.desktop \
      --replace-fail 'Name=OpenMW Launcher' 'Name=OpenMW Launcher (tes3mp)' \
      --replace-fail 'openmw-launcher' 'tes3mp-launcher' \
      --replace-fail 'Icon=openmw' 'Icon=tes3mp'
    substituteInPlace files/tes3mp-browser.desktop \
      --replace-fail 'Icon=openmw' 'Icon=tes3mp'

    grep -qF "recastnavigation/archive/${recast.rev}.zip" extern/CMakeLists.txt \
      || { echo "stale recastnavigation pin" >&2; exit 1; }

    # Boost 1.89 dropped the System library; its headers need no linking.
    substituteInPlace CMakeLists.txt \
      --replace-fail 'set(BOOST_COMPONENTS system filesystem' 'set(BOOST_COMPONENTS filesystem'
  '';

  nativeBuildInputs =
    [
      cmake
      pkg-config
    ]
    ++ lib.optionals buildServer [
      makeBinaryWrapper
    ]
    ++ lib.optionals (!buildServer) [
      copyDesktopItems
      libsForQt5.wrapQtAppsHook
    ];

  buildInputs =
    [
      SDL2
      boost
      libGL
      lz4
    ]
    ++ lib.optionals buildServer [
      luajit
      openscenegraph
    ]
    ++ lib.optionals (!buildServer) [
      bullet'
      ffmpeg_6
      libsForQt5.qtbase
      libxt
      mygui'
      openal
      osg'
      unshield
    ];

  cmakeFlags =
    [
      (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.10")
      (lib.cmakeFeature "RakNet_INCLUDES" "${crabnet}/include")
      (lib.cmakeFeature "RakNet_LIBRARY_RELEASE" "${crabnet}/lib/libRakNetLibStatic.a")
      (lib.cmakeFeature "RakNet_LIBRARY_DEBUG" "${crabnet}/lib/libRakNetLibStatic.a")
      # Deliberately upstream's pin rather than the system recastnavigation.
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_RECASTNAVIGATION" "${recast}")
      (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
      (lib.cmakeBool "BUILD_OPENCS" false)
      (lib.cmakeBool "BUILD_BSATOOL" false)
      (lib.cmakeBool "BUILD_ESMTOOL" false)
      (lib.cmakeBool "BUILD_NIFTEST" false)
      (lib.cmakeBool "BUILD_ESSIMPORTER" false)
      (lib.cmakeBool "BUILD_MASTER" false)
      (lib.cmakeFeature "BINDIR" "${placeholder "out"}/share/tes3mp")
      (lib.cmakeFeature "DATADIR" "${placeholder "out"}/share/tes3mp")
      (lib.cmakeFeature "SYSCONFDIR" "${placeholder "out"}/share/tes3mp")
      (lib.cmakeFeature "GLOBAL_CONFIG_PATH" "${placeholder "out"}/share")
      (lib.cmakeFeature "GLOBAL_DATA_PATH" "${placeholder "out"}/share")
      (lib.cmakeFeature "LICDIR" "${placeholder "out"}/share/licenses/tes3mp")
    ]
    ++ lib.optionals buildServer [
      (lib.cmakeBool "BUILD_OPENMW" false)
      (lib.cmakeBool "BUILD_LAUNCHER" false)
      (lib.cmakeBool "BUILD_WIZARD" false)
      (lib.cmakeBool "BUILD_BROWSER" false)
      (lib.cmakeBool "BUILD_MWINIIMPORTER" false)
    ]
    ++ lib.optionals (!buildServer) [
      (lib.cmakeBool "BUILD_OPENMW_MP" false)
    ];

  env =
    {
      LANG = "C.UTF-8";
    }
    // lib.optionalAttrs buildServer {
      NIX_CFLAGS_COMPILE = "-fpermissive";
    };

  dontWrapQtApps = true;

  postInstall =
    ''
      rm $out/share/pixmaps/openmw.png $out/share/metainfo/openmw.appdata.xml
      rmdir $out/share/metainfo

      mkdir -p $out/bin
    ''
    + lib.optionalString buildServer ''
      ln -s $out/share/tes3mp/tes3mp-server $out/bin/tes3mp-server
      rm $out/share/tes3mp/tes3mp-client-default.cfg
      rm $out/share/applications/org.openmw.launcher.desktop
      rmdir $out/share/applications $out/share/pixmaps

      # Copied: nixpkgs' Lua packages keep luarocks and its tools in their runtime closure.
      install -Dm755 ${lua-cjson'}/lib/lua/${luajit.luaversion}/cjson.so $out/lib/tes3mp/cjson.so
    ''
    + lib.optionalString (!buildServer) ''
      rm $out/share/tes3mp/tes3mp-server-default.cfg

      ln -s $out/share/tes3mp/tes3mp $out/bin/tes3mp
      ln -s $out/share/tes3mp/tes3mp-browser $out/bin/tes3mp-browser
      ln -s $out/share/tes3mp/openmw-launcher $out/bin/tes3mp-launcher
      ln -s $out/share/tes3mp/openmw-wizard $out/bin/tes3mp-wizard

      mv $out/share/applications/org.openmw.launcher.desktop $out/share/applications/tes3mp-launcher.desktop
      install -Dm644 ../files/tes3mp/tes3mp_logo.png $out/share/pixmaps/tes3mp.png
    '';

  postFixup =
    lib.optionalString buildServer ''
      wrapProgram $out/share/tes3mp/tes3mp-server \
        --prefix LUA_CPATH ';' "$out/lib/tes3mp/?.so"
    ''
    + lib.optionalString (!buildServer) ''
      wrapQtApp $out/share/tes3mp/openmw-launcher
      wrapQtApp $out/share/tes3mp/openmw-wizard
      wrapQtApp $out/share/tes3mp/tes3mp-browser
    '';

  desktopItems = lib.optionals (!buildServer) [
    (makeDesktopItem {
      name = "tes3mp";
      exec = "tes3mp";
      icon = "tes3mp";
      comment = finalAttrs.meta.description;
      desktopName = "TES3MP";
      categories = ["Game" "RolePlaying"];
    })
  ];

  stripDebugList = ["share/tes3mp"];
  separateDebugInfo = true;

  passthru = {
    inherit crabnet;
    updateScript = nix-update-script {
      extraArgs = ["--version-regex=^tes3mp-([0-9.]+)$"];
    };
  };

  meta = {
    description = "Multiplayer for The Elder Scrolls III: Morrowind, based on OpenMW";
    homepage = "https://tes3mp.com";
    license = lib.licenses.gpl3Only;
    mainProgram =
      if buildServer
      then "tes3mp-server"
      else "tes3mp";
    maintainers = with lib.maintainers; [sirius902];
    platforms = ["x86_64-linux"];
  };
})
