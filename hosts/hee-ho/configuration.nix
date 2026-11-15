{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/standard.nix
    ../../modules/microvms
    ./vms/anchor.nix
    ./vms/atm10.nix
    ./vms/rl2.nix
    ./vms/svends.nix
    ./vms/synergyds.nix
    ./eno2-e1000e-hang-workaround.nix
  ];

  networking.hostId = "b0e08309";

  my.microvmOwner = "chris";

  my.tailscale.enable = true;
  my.memory = {
    enable = true;
    ramGiB = 32;
  };

  # 32069 is hkmp; the microVMs open their own ports (vms/).
  networking.firewall.allowedTCPPorts = [25566 32069];
  networking.firewall.allowedUDPPorts = [25566 32069];

  # Must be enabled due to https://github.com/tailscale/tailscale/issues/4254.
  services.resolved.enable = true;

  services.tailscale = {
    useRoutingFeatures = "server";
    extraSetFlags = ["--advertise-exit-node" "--advertise-routes=192.168.1.0/24"];
  };

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
