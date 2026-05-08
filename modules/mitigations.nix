{
  config,
  lib,
  pkgs,
  ...
}: let
  kernelVersion = config.boot.kernelPackages.kernel.version;
in {
  boot.extraModprobeConfig = let
    # FUTURE(Sirius902) Temporary https://copy.fail/ mitigation.
    # https://discourse.nixos.org/t/is-nixos-affected-by-copy-fail-edit-yes-it-is/77317/10
    needsCopyFailMitigation =
      (lib.versionOlder kernelVersion "6.18.22")
      || (lib.versionAtLeast kernelVersion "6.19" && lib.versionOlder kernelVersion "6.19.12");
  in
    lib.optionalString needsCopyFailMitigation ''
      install algif_aead ${pkgs.coreutils}/bin/false
    ''
    # FUTURE(Sirius902) Temporary Dirty Frag mitigation.
    # https://github.com/V4bel/dirtyfrag
    + ''
      install esp4 ${pkgs.coreutils}/bin/false
      install esp6 ${pkgs.coreutils}/bin/false
      install rxrpc ${pkgs.coreutils}/bin/false
    '';
}
