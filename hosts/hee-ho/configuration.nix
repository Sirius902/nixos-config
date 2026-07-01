{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/standard.nix
    ./atm10-test.nix
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

  services.minecraft-servers = {
    enable = true;
    admins = ["chris"];
    servers.atm10 = {
      openFirewall = true;
      memoryMax = "20G";
      zfsDataset = "data/mc/atm10";
    };
  };

  # Allow ports for a second (not-yet-ported) mc server and hkmp.
  # atm10's 25565 is opened by services.minecraft-servers.
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
