{
  inputs,
  lib,
  pkgs,
  ...
}: {
  my.microvms.anchor = {
    vcpu = 2;
    memory = 1024;
    # Upstream hardcodes net.Listen("tcp", ":43383"); no flag, environment
    # variable or config file reaches it.
    ports.tcp = [43383];
    egress = "none";
    oomScoreAdjust = 500;
    data = {
      dataset = "data/srv/anchor";
      path = "/media/data/srv/anchor";
    };
    guest.services.anchor-server = {
      enable = true;
      package = inputs.secrets.lib.overrideAnchorServer lib pkgs.anchor-server;
    };
  };
}
