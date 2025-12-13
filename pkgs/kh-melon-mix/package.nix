{
  fetchFromGitHub,
  flac,
  lua5_4_compat,
  makeWrapper,
  melonDS,
  nix-update-script,
}:
melonDS.overrideAttrs (prevAttrs: {
  pname = "kh-melon-mix";
  version = "0.7.1-unstable-2025-12-13";

  src = fetchFromGitHub {
    owner = "vitor251093";
    repo = "KHMelonMix";
    rev = "0d8985de3d8ef39d0350b6644c7bdd834e145f3d";
    hash = "sha256-OZ7z+lqMdJoYT/E7hsB3rJQhY4I1P4imBXGYDlpKpvQ=";
  };

  nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [makeWrapper];

  buildInputs =
    (prevAttrs.buildInputs or [])
    ++ [
      flac
      lua5_4_compat
    ];

  qtWrapperArgs = (prevAttrs.qtWrapperArgs) ++ ["--set QT_QPA_PLATFORM xcb"];

  postInstall =
    ''
      mv $out/bin/melonDS $out/bin/MelonMix
    ''
    + (prevAttrs.postInstall or "");

  postFixup =
    (prevAttrs.postFixup or "")
    + ''
      # Setup cwd to a directory where we can install custom assets.
      wrapProgram $out/bin/MelonMix \
        --run 'CWD_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/kh-melon-mix"; mkdir -p "$CWD_DIR"; cd "$CWD_DIR"'
    '';

  passthru.updateScript = nix-update-script {extraArgs = ["--version=branch"];};
})
