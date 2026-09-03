{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/standard.nix
    ../../modules/microvm-host.nix
    ./anchor-vm.nix
    ./atm10-vm.nix
    ./eno2-e1000e-hang-workaround.nix
  ];

  networking.hostId = "b0e08309";

  my.microvmHost = {
    enable = true;
    externalInterface = "eno2";
    identityFile = "/home/chris/.ssh/id_ed25519";
  };

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

  # 32069 is hkmp; atm10's 25565 and anchor's 43383 are DNAT'd to their microVMs
  # (<vm>-hostnet), not opened here.
  networking.firewall.allowedTCPPorts = [25566 32069];
  networking.firewall.allowedUDPPorts = [25566 32069];

  # Must be enabled due to https://github.com/tailscale/tailscale/issues/4254.
  services.resolved.enable = true;
  services.tailscale.useRoutingFeatures = "server";

  # Keep the OOM-killer off the remote-access path under memory pressure (sshd is
  # already -1000; the atm10 microVM is set to be sacrificed first).
  systemd.services.tailscaled.serviceConfig.OOMScoreAdjust = -900;

  environment.systemPackages = with pkgs; [
    ghostty.terminfo
    config.my.jdk
  ];

  environment.pathsToLink = [
    "/share/terminfo"
  ];
}
