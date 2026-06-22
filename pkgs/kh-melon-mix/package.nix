{
  fetchFromGitHub,
  flac,
  lua5_4_compat,
  makeWrapper,
  melonds,
  nix-update-script,
}:
melonds.overrideAttrs (prevAttrs: {
  pname = "kh-melon-mix";
  version = "0.8.2-unstable-2026-06-22";

  src = fetchFromGitHub {
    owner = "vitor251093";
    repo = "KHMelonMix";
    rev = "e4eaf799c7e5ec6804a7831ac975cfd74d0d1419";
    hash = "sha256-qNcX7HbMZARybeTjNXvUX5b89rbKlexRsX0i7a6xFoo=";
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

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch"
      "--version-regex=v(.*)"
    ];
  };

  meta =
    (prevAttrs.meta or {})
    // {
      homepage = "https://github.com/vitor251093/KHMelonMix";
      mainProgram = "MelonMix";
    };
})
