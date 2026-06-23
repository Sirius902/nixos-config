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
  my.memory = {
    enable = true;
    ramGiB = 32;
    arcMaxGiB = 8; # ARC down from the derived 12 to clear the 12G Minecraft JVM cgroup
  };

  users.users.chris.extraGroups = ["svends" "synergyds"];

  services.svends = {
    enable = true;
    autoStart = false;
    openFirewall = true;
    insecure = true;
  };

  services.synergyds = {
    enable = true;
    autoStart = false;
    openFirewall = true;
    insecure = true;
    extraCommandLine = inputs.secrets.lib.srcdsExtraCommandLine;
  };

  services.minecraft-servers = {
    enable = true;
    admins = ["chris"]; # chris joins each mc-<name> group: console (jscreen) + file access
    servers.atm10 = {
      openFirewall = true; # opens 25565
      memoryMax = "20G"; # -Xmx8G + 4G headroom for non-heap (metaspace, threads, direct buffers, mmap); observed peak ~8.8G
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
