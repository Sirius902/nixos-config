{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/minimal.nix
    ../../modules/openssh.nix
    ../../modules/documentation.nix
    ../../modules/tailscale.nix
  ];

  networking.hostId = "b0e08309";

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

  # TODO: Get systemd service to work. Use this instead of cron job.
  # systemd.timers."mc-backup" = {
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     OnBootSec = "1h";
  #     OnUnitActiveSec = "1h";
  #     Unit = "mc-backup.service";
  #   };
  # };
  #
  # systemd.services."mc-backup" = {
  #   path = [
  #     pkgs.bash
  #     pkgs.gawk
  #     pkgs.gnutar
  #     pkgs.screen
  #   ];
  #   script = ''
  #     set -eu
  #     ${pkgs.bash}/bin/bash /media/data/mc/backup-all.sh
  #   '';
  #   serviceConfig = {
  #     Type = "oneshot";
  #     User = "chris";
  #     Group = "users";
  #     IgnoreSIGPIPE = false;
  #   };
  # };

  environment.systemPackages = with pkgs; [
    ghostty.terminfo
    screen
    config.my.jdk
  ];

  environment.pathsToLink = [
    "/share/terminfo"
  ];

  # Fix waiting for WiFi on rebuild.
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
}
