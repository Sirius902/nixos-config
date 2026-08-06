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
  version = "0.9.1-unstable-2026-08-06";

  src = fetchFromGitHub {
    owner = "vitor251093";
    repo = "KHMelonMix";
    rev = "a0970dfc8bb2ac2095c9e677641a529a7adbf698";
    hash = "sha256-YqSV10PYrcsP+QH6JK90tmWIUVQjMbkG8iHfa7LeDcs=";
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
