{
  lib,
  python313,
  fetchFromGitHub,
  fetchPypi,
  xsel,
  xclip,
  mtdev,
  zenity,
  cmake,
  s2clientprotocol,
  nix-update-script,
}: let
  python3 = python313.override {
    packageOverrides = pyfinal: pyprev: {
      inherit s2clientprotocol;
    };
  };

  pyevermizer = python3.pkgs.buildPythonPackage rec {
    pname = "pyevermizer";
    version = "0.50.1";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-zVbMom7ZZ1eQFU3XBAKtKKOB/DyQMb0C65sdrYwxc5g=";
    };
  };

  maseya-z3pr = python3.pkgs.buildPythonPackage rec {
    pname = "maseya-z3pr";
    version = "1.0.0rc1";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-wCj9syUrSuLIbwfsyZY2n+Oar+s7oxQBG/Y3Ilf4Z8U=";
    };
  };

  factorio-rcon-py = python3.pkgs.buildPythonPackage rec {
    pname = "factorio_rcon_py";
    version = "2.1.3";
    pyproject = true;

    build-system = with python3.pkgs; [setuptools];

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-hL/ELSrfzQFmC9QDZSxkU/a+K0dIF+IU51IG8CsVEsM=";
    };
  };

  setuptools-cmake-helper = python3.pkgs.buildPythonPackage rec {
    pname = "setuptools_cmake_helper";
    version = "0.1.2";
    pyproject = true;

    build-system = with python3.pkgs; [setuptools-scm];

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-U0hFtthr98iZ3Jvrynj+ElF28nCiu+VKqkzPw6jfoIk=";
    };
  };

  dolphin-memory-engine = python3.pkgs.buildPythonPackage rec {
    pname = "dolphin_memory_engine";
    version = "1.3.0";
    pyproject = true;

    nativeBuildInputs = [
      cmake
    ];

    dontUseCmakeConfigure = true;

    build-system = with python3.pkgs; [setuptools-scm];

    dependencies = with python3.pkgs; [cython setuptools-cmake-helper];

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-WHvVf8eclF9GePYCotMW/3wbAisyE/xq3wXtLhuo2pI=";
    };
  };

  pymem = python3.pkgs.buildPythonPackage rec {
    pname = "pymem";
    version = "1.14.0";
    pyproject = true;

    build-system = with python3.pkgs; [poetry-core];

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-KfbDK8rQAyiIr6ut+X0eTHdX+Ihz3k159/TB35uefvE=";
    };
  };

  zilliandomizer = python3.pkgs.buildPythonPackage rec {
    pname = "pymem";
    version = "0.9.1";
    pyproject = true;

    build-system = with python3.pkgs; [setuptools-scm];

    src = fetchFromGitHub {
      owner = "beauxq";
      repo = "zilliandomizer";
      tag = "v${version}";
      hash = "sha256-8QkjVl7kNjpww64bs8UpSdpMhpdtYGyILYjxwMgZWoc=";
    };
  };

  xxtea = python3.pkgs.buildPythonPackage rec {
    pname = "xxtea";
    version = "3.3.0";
    pyproject = true;

    build-system = with python3.pkgs; [setuptools];

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-5DdCC99AuTF9adiO2D5ucNWBzXVV0WpudOyv/B1u/D8=";
    };
  };
in
  python3.pkgs.buildPythonApplication {
    pname = "archipelago";
    version = "0.6.3";
    format = "other";

    src = fetchFromGitHub {
      owner = "ArchipelagoMW";
      repo = "Archipelago";
      rev = "ecb22642af291e05bdc6ae729bb14d4d1ae83792";
      hash = "sha256-CGg2Jedwp6GyYhRmjy5AL0o1HKeaJmA2+RyJ9Zn28lY=";
    };

    buildInputs = [
      xsel
      xclip
      mtdev
    ];

    dependencies = with python3.pkgs; [
      setuptools

      pyevermizer
      maseya-z3pr
      websockets
      factorio-rcon-py
      nest-asyncio
      bsdiff4
      dolphin-memory-engine
      pymem
      zilliandomizer
      colorama
      websockets
      xxtea
      s2clientprotocol
      pyyaml
      jellyfish
      jinja2
      schema
      kivy
      platformdirs
      cymem
    ];

    prePatch = ''
      substituteInPlace requirements.txt \
        --replace "websockets>=13.0.1,<14" "websockets" \
        --replace "jellyfish>=1.1.3" "jellyfish>=1.1.2" \

      # TODO(Sirius902) Remove
      substituteInPlace worlds/_sc2common/requirements.txt \
        --replace "s2clientprotocol>=5.0.11.90136.0" "s2clientprotocol"
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/archipelago
      mv * $out/share/archipelago

      makeWrapper ${python3.interpreter} $out/bin/archipelago \
        --set PYTHONPATH "$PYTHONPATH:$out/share/archipelago" \
        --add-flags "-O $out/share/archipelago/Launcher.py"

      runHook postInstall
    '';

    passthru.updateScript = nix-update-script {extraArgs = ["--version=branch"];};

    meta = {
      description = "Multi-Game Randomizer and Server";
      homepage = "https://archipelago.gg";
      # changelog = "https://github.com/ArchipelagoMW/Archipelago/releases/tag/${version}";
      license = lib.licenses.mit;
      mainProgram = "archipelago";
      maintainers = with lib.maintainers; [
        # sirius902
      ];
      platforms = lib.platforms.linux;
    };
  }
