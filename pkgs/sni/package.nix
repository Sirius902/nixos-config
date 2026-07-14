{
  lib,
  buildGoModule,
  fetchFromGitHub,
  pkg-config,
  gtk3,
  libayatana-appindicator,
  nix-update-script,
}:
buildGoModule (finalAttrs: {
  pname = "sni";
  version = "0.0.100";

  src = fetchFromGitHub {
    owner = "alttpo";
    repo = "sni";
    tag = "v${finalAttrs.version}";
    hash = "sha256-1Wzsoffw/sQ0CWM9EhxPH4pSvbxfQ5GjHfQJc2cwr6M=";
  };

  vendorHash = "sha256-5qdNOUUlHILjJnRkcw58ZvDx1RMi1luWsBGcxyDCW3U=";

  nativeBuildInputs = [pkg-config];

  buildInputs = [
    gtk3
    libayatana-appindicator
  ];

  subPackages = ["cmd/sni"];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=v${finalAttrs.version}"
    "-X main.commit=${finalAttrs.src.rev}"
    "-X main.builtBy=nix"
  ];

  postInstall = ''
    install -Dm644 cmd/sni/apps.yaml $out/share/sni/apps.yaml
    cp -r lua $out/share/sni/lua
  '';

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Interface for retro game consoles to communicate with the outside world";
    homepage = "https://github.com/alttpo/sni";
    license = lib.licenses.mit;
    mainProgram = "sni";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
