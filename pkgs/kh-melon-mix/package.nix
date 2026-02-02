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
  version = "0.7.2-unstable-2026-02-02";

  src = fetchFromGitHub {
    owner = "vitor251093";
    repo = "KHMelonMix";
    rev = "25e913a3d98ada9a65ca73d1d14efedbd77fb467";
    hash = "sha256-nizAyjb0vU5m4/iG6vcBXLfaTJSdcv+KY0ksZow/mCc=";
  };

  nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [makeWrapper];

  buildInputs =
    (prevAttrs.buildInputs or [])
    ++ [
      flac
      lua5_4_compat
    ];

  qtWrapperArgs = (prevAttrs.qtWrapperArgs or []) ++ ["--set QT_QPA_PLATFORM xcb"];

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
