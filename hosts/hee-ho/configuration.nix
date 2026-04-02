{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/standard.nix
  ];

  networking.hostId = "b0e08309";

  my.tailscale.enable = true;
  my.jdk = pkgs.graalvmPackages.graalvm-oracle;

  users.users.chris.extraGroups = ["svends" "synergyds"];

  services.svends = {
    enable = true;
    openFirewall = true;
    insecure = true;
  };
  systemd.services.svends.wantedBy = lib.mkForce [];

  services.synergyds = {
    enable = true;
    openFirewall = true;
    insecure = true;
    extraCommandLine = inputs.secrets.lib.srcdsExtraCommandLine;
  };
  systemd.services.synergyds.wantedBy = lib.mkForce [];

  # Allow ports for mc and hkmp.
  networking.firewall.allowedTCPPorts = [25565 25566 32069];
  networking.firewall.allowedUDPPorts = [25565 25566 32069];

  # Must be enabled due to https://github.com/tailscale/tailscale/issues/4254.
  services.resolved.enable = true;
  services.tailscale.useRoutingFeatures = "server";

  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 * * * *    chris    /media/data/mc/backup-all.sh"
    ];
  };

  environment.systemPackages = with pkgs; [
    ghostty.terminfo
    screen
    config.my.jdk
  ];

  environment.pathsToLink = [
    "/share/terminfo"
  ];
}
