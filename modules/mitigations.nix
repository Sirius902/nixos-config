{
  config,
  lib,
  pkgs,
  ...
}: let
  kernelVersion = config.boot.kernelPackages.kernel.version;

  # FUTURE(Sirius902) CVE-2026-46333 (ssh-keysign-pwn): ptrace exit-race
  # allows unprivileged local users to steal FDs from privileged processes.
  # https://blog.qualys.com/vulnerabilities-threat-research/2026/05/20/cve-2026-46333-local-root-privilege-escalation-and-credential-disclosure-in-the-linux-kernel-ptrace-path
  needsPtraceMitigation =
    (lib.versionOlder kernelVersion "6.12.89")
    || (lib.versionAtLeast kernelVersion "6.13" && lib.versionOlder kernelVersion "6.18.31")
    || (lib.versionAtLeast kernelVersion "6.19" && lib.versionOlder kernelVersion "7.0.8");
in {
  boot.kernel.sysctl = lib.mkIf needsPtraceMitigation {
    "kernel.yama.ptrace_scope" = lib.mkDefault 2;
  };

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
