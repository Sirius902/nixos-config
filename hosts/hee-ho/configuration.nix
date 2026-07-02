{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/standard.nix
    ./atm10-vm.nix
  ];

  networking.hostId = "b0e08309";

  my.tailscale.enable = true;
  my.jdk = pkgs.graalvmPackages.graalvm-oracle;
  my.memory = {
    enable = true;
    ramGiB = 32;
  };

  users.users.chris.extraGroups = ["svends" "synergyds"];

  services.svends = {
    enable = true;
    autoStart = false;
    openFirewall = true;
    insecure = true;
  };

  sops.secrets.srcdsExtraCommandLine = {};
  services.synergyds = {
    enable = true;
    autoStart = false;
    openFirewall = true;
    insecure = true;
    extraCommandLineFile = config.sops.secrets.srcdsExtraCommandLine.path;
  };

  # 32069 is hkmp; atm10's 25565 is DNAT'd to its microVM (atm10-vm-hostnet), not here.
  networking.firewall.allowedTCPPorts = [25566 32069];
  networking.firewall.allowedUDPPorts = [25566 32069];

  # Must be enabled due to https://github.com/tailscale/tailscale/issues/4254.
  services.resolved.enable = true;
  services.tailscale.useRoutingFeatures = "server";

  environment.systemPackages = with pkgs; [
    ghostty.terminfo
    config.my.jdk
  ];

  environment.pathsToLink = [
    "/share/terminfo"
  ];
}
