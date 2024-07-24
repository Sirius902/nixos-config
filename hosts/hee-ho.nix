{ pkgs, ... }:

{
  boot.zfs.extraPools = [ "data" ];

  # Allow ports for mc.
  networking.firewall.allowedTCPPorts = [ 25565 25566 ];
  networking.firewall.allowedUDPPorts = [ 25565 25566 ];

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
    screen
    temurin-jre-bin
  ];
}
