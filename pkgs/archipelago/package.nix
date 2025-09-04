{
  lib,
  python3Packages,
  fetchFromGitHub,
  nix-update-script,
}:
python3Packages.buildPythonApplication rec {
  pname = "archipelago";
  version = "0.6.3-unstable-2025-09-04";
  format = "setup.py";

  src = fetchFromGitHub {
    owner = "ArchipelagoMW";
    repo = "Archipelago";
    rev = "42ace29db46f0fed3e2557ea77e84954d28c6042";
    hash = "sha256-W+4AheLKGGrPB2gu7WMl3u7ys9CPoy2GZD57atxTHus=";
  };

  passthru.updateScript = nix-update-script {extraArgs = ["--version=branch"];};

  meta = {
    description = "Multi-Game Randomizer and Server";
    homepage = "https://archipelago.gg";
    changelog = "https://github.com/ArchipelagoMW/Archipelago/releases/tag/${builtins.elemAt (lib.splitString "-" version) 0}";
    license = lib.licenses.mit;
    mainProgram = "archipelago";
    maintainers = with lib.maintainers; [
      # sirius902
    ];
    platforms = lib.platforms.linux;
  };
}
