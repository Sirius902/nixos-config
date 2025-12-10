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
  version = "0.7.1-unstable-2025-12-10";

  src = fetchFromGitHub {
    owner = "vitor251093";
    repo = "KHMelonMix";
    rev = "e2316ef38dd2c3415003e35928fcb9ca3cce50f5";
    hash = "sha256-B2WbA20uTM6qctOkn60kHqbxjoo2/Kuok62zZLn/VgI=";
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
