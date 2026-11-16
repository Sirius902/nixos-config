{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:
buildGoModule {
  pname = "anchor-server";
  version = "0-unstable-2026-11-15";

  src = fetchFromGitHub {
    owner = "garrettjoecox";
    repo = "anchor";
    rev = "55971905898c5716d9e14896034b02d676eeda36";
    hash = "sha256-haS5/yqIEZW2FTmOFw/Iwkae0Uxu8JmGBx+N4c+eRFI=";
  };

  __structuredAttrs = true;

  vendorHash = "sha256-gV5uQW5jk4Cd647RZwx58d728JQe+CjHPBrJXIIEeGs=";

  env.CGO_ENABLED = 0;

  postInstall = ''
    mv "$out/bin/anchor" "$out/bin/anchor-server"
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch"
      "--version-regex=(0-unstable-.*)"
    ];
  };

  meta = {
    description = "Client/server service providing multiplayer functions in Harbor Masters 64 ports";
    homepage = "https://github.com/garrettjoecox/anchor";
    license = lib.licenses.unfree;
    mainProgram = "anchor-server";
    maintainers = with lib.maintainers; [sirius902];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
