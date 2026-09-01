{
  fetchFromGitHub,
  flac,
  lib,
  lua5_4_compat,
  makeWrapper,
  melonds,
  nix-update-script,
  stdenv,
}:
melonds.overrideAttrs (prevAttrs: {
  pname = "kh-melon-mix";
  version = "0.9.3-unstable-2026-09-01";

  src = fetchFromGitHub {
    owner = "vitor251093";
    repo = "KHMelonMix";
    rev = "9da35b59e1b88e3dc45c88070e3052f799fcccdf";
    hash = "sha256-AYV8sz0wNAeE//WMPYjuHUoUCmFNPIp84utzn5sxSDo=";
  };

  nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [makeWrapper];

  buildInputs =
    (prevAttrs.buildInputs or [])
    ++ [
      flac
      lua5_4_compat
    ];

  qtWrapperArgs =
    (prevAttrs.qtWrapperArgs or [])
    ++ lib.optionals stdenv.hostPlatform.isLinux ["--set QT_QPA_PLATFORM xcb"];

  # A bare melonDS collides with nixpkgs' melonds in a profile, so rename the
  # entry point on both platforms.
  postInstall =
    lib.optionalString stdenv.hostPlatform.isLinux ''
      mv $out/bin/melonDS $out/bin/MelonMix
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      mv $out/Applications/melonDS.app $out/Applications/MelonMix.app
      mv $out/Applications/MelonMix.app/Contents/MacOS/{melonDS,MelonMix}
      substituteInPlace $out/Applications/MelonMix.app/Contents/Info.plist \
        --replace-fail "<string>melonDS</string>" "<string>MelonMix</string>"
    ''
    + (prevAttrs.postInstall or "");

  # Wrap the bundled binary rather than a separate bin/ wrapper so Finder and
  # `open` launches get the cwd shim too, and the real executable stays inside
  # the bundle so NSBundle mainBundle still resolves. postFixup runs after
  # wrapQtAppsHook, so this nests on the Qt wrapper; the bin/ symlink is created
  # too late for the hook to follow and double-wrap it.
  postFixup = let
    program =
      if stdenv.hostPlatform.isDarwin
      then "$out/Applications/MelonMix.app/Contents/MacOS/MelonMix"
      else "$out/bin/MelonMix";
  in
    (prevAttrs.postFixup or "")
    + ''
      # Setup cwd to a directory where we can install custom assets.
      wrapProgram ${program} \
        --run 'CWD_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/kh-melon-mix"; mkdir -p "$CWD_DIR"; cd "$CWD_DIR"'
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      mkdir -p $out/bin
      ln -s ${program} $out/bin/MelonMix
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
      maintainers = with lib.maintainers; [sirius902];
    };
})
