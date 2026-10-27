{
  lib,
  clangStdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  python3,
  glslang,
  gitMinimal,
  llvmPackages,
  ffmpeg,
  sdl3,
  dejavu_fonts,
  versionCheckHook,
  nix-update-script,
}: let
  fetchContentSources = {
    opus = fetchFromGitHub {
      owner = "xiph";
      repo = "opus";
      rev = "ddbe48383984d56acd9e1ab6a090c54ca6b735a6";
      hash = "sha256-XUj2mV+5SVPGa6ZKTPa/eY5xVwkpPmCuGULxrVG0VOE=";
      # Opus derives its version from git metadata or a release tarball's package_version.
      postFetch = ''
        echo 'PACKAGE_VERSION="1.5.2"' > "$out/package_version"
      '';
    };
    xbyak = fetchFromGitHub {
      owner = "herumi";
      repo = "xbyak";
      rev = "44a72f369268f7d552650891b296693e91db86bb";
      hash = "sha256-S4arAwbhTGsUhDFfy5fTGyDvCm0/x/LKiiPTAuRM8Yk=";
    };
    zydis = fetchFromGitHub {
      owner = "zyantific";
      repo = "zydis";
      rev = "120e0e705f8e3b507dc49377ac2879979f0d545c";
      fetchSubmodules = true;
      hash = "sha256-bjQCaYRA94CGBsxG+UOuDDyLrH3k2ERJbn0+7ITGLeU=";
    };
    zstd = fetchFromGitHub {
      owner = "facebook";
      repo = "zstd";
      rev = "f8745da6ff1ad1e7bab384bd1f9d742439278e99";
      hash = "sha256-tNFWIT9ydfozB8dWcmTMuZLCQmQudTFJIkSr0aG7S44=";
    };
    zarchive_source = fetchFromGitHub {
      owner = "Exzap";
      repo = "ZArchive";
      rev = "d2c717730092c7bf8cbb033b12fd4001b7c4d932";
      hash = "sha256-hX637O/mVLTzmG0a9swJu9w+3o26VHo+K/9RhMuf1lI=";
    };
  };
in
  clangStdenv.mkDerivation (finalAttrs: {
    pname = "kytyps5";
    version = "0-unstable-2026-10-26";

    src = fetchFromGitHub {
      owner = "KytyPS5";
      repo = "KytyPS5";
      rev = "986721f5bca49e20d0e3312782882429dd5cfcb6";
      hash = "sha256-0of1j0s6ybcd1LWm28k6+8HBx45RW3gzV7Pi5G8bJNA=";
      postCheckout = ''
        git -C "$out" log -1 --pretty=%ct > "$out/SOURCE_DATE_EPOCH"

        git -C "$out/3rdparty" submodule update --init --depth 1 \
          LibAtrac9 \
          SPIRV-Headers \
          SPIRV-Tools \
          Vulkan-Headers \
          VulkanMemoryAllocator \
          fmt \
          imgui \
          magic_enum \
          nlohmann_json \
          spdlog \
          tracy \
          xxHash
      '';
    };

    postPatch = ''
      check_pin() {
        local name="$1" url="$2" expected="$3" actual
        actual=$(sed -n "\|GIT_REPOSITORY $url|{n;s/^[[:space:]]*GIT_TAG[[:space:]]*\([0-9a-f]\{40\}\).*/\1/p}" 3rdparty/CMakeLists.txt)
        if [[ "$actual" != "$expected" ]]; then
          echo "error: $name pin changed upstream: expected '$expected', got '$actual'" >&2
          echo "update $name in package.nix" >&2
          exit 1
        fi
      }
      ${lib.concatLines (lib.mapAttrsToList (name: src: "check_pin ${name} ${src.gitRepoUrl} ${src.rev}") fetchContentSources)}

      # The ffmpeg-core submodule downloads a prebuilt static FFmpeg at configure time.
      install -Dm644 ${./ffmpeg.cmake} 3rdparty/ffmpeg-core/CMakeLists.txt
      # The SDL3 submodule builds statically and dlopens its backends by soname.
      install -Dm644 ${./sdl3.cmake} 3rdparty/SDL3/CMakeLists.txt

      # A FETCHCONTENT_SOURCE_DIR override skips the declaration's PATCH_COMMAND.
      cp -r ${fetchContentSources.zarchive_source} zarchive-src
      chmod -R u+w zarchive-src
      git -C zarchive-src apply --ignore-whitespace ../3rdparty/patches/zarchive-reader.patch
      cmakeFlags+=("-DFETCHCONTENT_SOURCE_DIR_ZARCHIVE_SOURCE=$PWD/zarchive-src")

      substituteInPlace src/generate_version.cmake \
        --replace-fail 'set(KYTY_GIT_VERSION "unknown")' 'set(KYTY_GIT_VERSION "${finalAttrs.version}")' \
        --replace-fail 'set(KYTY_GIT_HASH "unknown")' 'set(KYTY_GIT_HASH "${lib.substring 0 7 finalAttrs.src.rev}")' \
        --replace-fail 'set(KYTY_GIT_REVISION "unknown")' 'set(KYTY_GIT_REVISION "${finalAttrs.src.rev}")'

      # The version banner's date is __DATE__, which clang takes from SOURCE_DATE_EPOCH.
      export SOURCE_DATE_EPOCH=$(cat SOURCE_DATE_EPOCH)

      substituteInPlace src/graphics/presentation/systemOverlay.cpp \
        --replace-fail /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf ${dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf
    '';

    nativeBuildInputs = [
      cmake
      ninja
      pkg-config
      python3
      glslang
      gitMinimal
      llvmPackages.bintools
    ];

    buildInputs = [
      ffmpeg
      sdl3
    ];

    cmakeFlags =
      [
        (lib.cmakeBool "KYTY_BUILD_LAUNCHER" false)
        (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
      ]
      ++ lib.mapAttrsToList (name: src: lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_${lib.toUpper name}" "${src}") (removeAttrs fetchContentSources ["zarchive_source"]);

    ninjaFlags = ["kyty_emulator"];

    strictDeps = true;
    __structuredAttrs = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/${finalAttrs.pname}
      cp -r kyty_emulator assets $out/share/${finalAttrs.pname}/
      ln -s ../share/${finalAttrs.pname}/kyty_emulator $out/bin/kyty_emulator

      install -Dm644 -t $out/share/licenses/${finalAttrs.pname} ../LICENSE ../LICENSES/Kyty-MIT.txt
      install -Dm644 -t $out/share/licenses/${finalAttrs.pname}/opus ${fetchContentSources.opus}/COPYING

      runHook postInstall
    '';

    nativeInstallCheckInputs = [versionCheckHook];
    versionCheckProgramArg = "--help";
    doInstallCheck = true;

    passthru.updateScript = nix-update-script {
      extraArgs = [
        "--version=branch"
        "--version-regex=(0-unstable-.*)"
      ];
    };

    meta = {
      description = "PlayStation 5 emulator";
      homepage = "https://github.com/KytyPS5/KytyPS5";
      license = lib.licenses.gpl2Only;
      maintainers = with lib.maintainers; [sirius902];
      mainProgram = "kyty_emulator";
      platforms = ["x86_64-linux"];
    };
  })
