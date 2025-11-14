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
  version = "0.7.1-unstable-2025-11-13";

  src = fetchFromGitHub {
    owner = "vitor251093";
    repo = "KHMelonMix";
    rev = "c44f19f23a4594955fe87ffa81d855312c19d04a";
    hash = "sha256-Cmj235FpBB4EFWJHXy7M9oz3Q2bGn33eIgl6ra48Aws=";
  };

  patches = [./fix-build-qt-6.10.patch];

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
