{
  lib,
  stdenv,
  cmake,
  fetchFromGitHub,
  openssl,
  python311,
  runCommand,
  runCommandCC,
  writeText,
  nix-update-script,
}: let
  pythonEnv = python311.withPackages (ps: [
    ps.pyyaml
    ps.websockets
    ps.schema
    ps.typing-extensions
  ]);
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "apcpp-glue";
    version = "0-unstable-2026-01-13";

    src = fetchFromGitHub {
      owner = "RecompRando";
      repo = "MMRecompAPCppGlue";
      rev = "236359fc502eb2f52c47dae0c283fc80c395e971";
      hash = "sha256-4G1VHecqGVrydHju6g05GQcW4+bDKS1apjCmciV9EUY=";
      fetchSubmodules = true;
    };

    nativeBuildInputs = [
      cmake
      pythonEnv
    ];

    buildInputs = [
      openssl
      python311
    ];

    hardeningDisable = ["format"];

    postPatch = ''
      cat > PythonStandalone_Linux_x64.cmake <<EOF
      add_library(python_standalone INTERFACE)
      target_include_directories(python_standalone INTERFACE "${python311}/include/python3.11")
      target_link_libraries(python_standalone INTERFACE "${python311}/lib/libpython3.11.so")
      set(PYTHON_EXE "${pythonEnv}/bin/python3.11")
      function(link_python_standalone TARGET_NAME)
      endfunction()
      EOF

      substituteInPlace CMakeLists.txt \
        --replace-fail 'set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)' "" \
        --replace-fail 'set(CMAKE_INSTALL_RPATH "$\{ORIGIN\}")' ""

      # The embedded interpreter only searches the paths the host sets, so give
      # it a real stdlib after the zip; the zip's dummy modules keep shadowing.
      substituteInPlace apcpp-solo-gen.cpp \
        --replace-fail \
          'PyWideStringList_Append(&config.module_search_paths, zip_path);' \
          'PyWideStringList_Append(&config.module_search_paths, zip_path);
          PyWideStringList_Append(&config.module_search_paths, L"${python311}/lib/python3.11");
          PyWideStringList_Append(&config.module_search_paths, L"${python311}/lib/python3.11/lib-dynload");' \
        --replace-fail 'PyRun_SimpleString("sys.path.pop()");' ""

      # local_path falls back to the CWD, which the game pins to its own
      # read-only bin dir; give Archipelago a writable data dir instead.
      substituteInPlace archipelago/Utils.py \
        --replace-fail \
          'local_path.cached_path = os.path.abspath(".")' \
          'local_path.cached_path = os.path.join(os.getenv("XDG_DATA_HOME") or os.path.expanduser("~/.local/share"), "Zelda64Recompiled"); os.makedirs(local_path.cached_path, exist_ok=True)'

      cat >> apcpp-solo-gen.cpp <<EOF
      // The game dlopens this library RTLD_LOCAL, hiding libpython from the
      // stdlib's C extension modules, which expect its symbols to be global.
      #include <dlfcn.h>
      __attribute__((constructor)) static void nix_promote_libpython(void) {
          dlopen("${python311}/lib/libpython3.11.so.1.0", RTLD_NOW | RTLD_GLOBAL);
      }
      EOF

      substituteInPlace minipelago/package.py \
        --replace-fail \
          'os.path.join(site_packages, "site-packages", package)' \
          'os.path.join("${pythonEnv}/${pythonEnv.sitePackages}", package)' \
        --replace-fail \
          'zipf.write(src, arcname)' \
          'zipf.writestr(zipfile.ZipInfo(arcname, (1980, 1, 1, 0, 0, 0)), open(src, "rb").read(), zipfile.ZIP_DEFLATED)' \
        --replace-fail '"schema.py",' '"schema",'
    '';

    installPhase = ''
      runHook preInstall

      install -Dm755 libAPCpp-Glue.so $out/lib/apcpp-glue/APCpp-Glue.so
      install -Dm644 minipelago.zip $out/share/apcpp-glue/minipelago.zip

      runHook postInstall
    '';

    passthru = {
      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch"
          "--version-regex=(0-unstable-.*)"
        ];
      };

      # The interpreter embedded in an RTLD_LOCAL-loaded plugin, like the
      # game loads it; stdlib C extensions only resolve if the constructor
      # promoted libpython into the global namespace.
      tests.embedded = runCommandCC "apcpp-glue-test-embedded" {} ''
        cat > harness.c <<EOF
        #include <dlfcn.h>
        #include <stdio.h>
        int main(void) {
          void *h = dlopen("${finalAttrs.finalPackage}/lib/apcpp-glue/APCpp-Glue.so", RTLD_NOW | RTLD_LOCAL);
          if (!h) { fprintf(stderr, "dlopen: %s\n", dlerror()); return 1; }
          void (*init)(void) = dlsym(h, "Py_Initialize");
          int (*run)(const char *) = dlsym(h, "PyRun_SimpleString");
          if (!init || !run) { fprintf(stderr, "dlsym failed\n"); return 1; }
          init();
          return run("import zlib, hashlib; print('extensions OK')") != 0;
        }
        EOF
        $CC harness.c -o harness
        export PYTHONHOME=${python311}
        ./harness
        touch $out
      '';

      # Solo seed generation, run exactly like the in-game generator: the
      # minipelago zip first on sys.path, stdlib after, unwritable CWD.
      tests.generate = let
        yaml = writeText "Player1.yaml" ''
          name: Player1
          game: "Majora's Mask Recompiled"
          "Majora's Mask Recompiled": {}
        '';
        script = writeText "generate-test.py" ''
          import sys

          sys.path.insert(0, "${finalAttrs.finalPackage}/share/apcpp-glue/minipelago.zip")
          sys.argv = ["MMGenerate.py", "--player_files_path", "players", "--outputpath", "out"]
          import MMGenerate

          print("seed:", MMGenerate.main())
        '';
      in
        runCommand "apcpp-glue-test-generate" {} ''
          export HOME=$TMPDIR
          cd $TMPDIR
          mkdir -p players out
          cp ${yaml} players/Player1.yaml
          ${python311}/bin/python3.11 -I ${script}
          ls out/AP_*_solo.zip
          touch $out
        '';
    };

    meta = {
      homepage = "https://github.com/RecompRando/MMRecompAPCppGlue";
      description = "Archipelago native glue library for MMRecompRando";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
    };
  })
