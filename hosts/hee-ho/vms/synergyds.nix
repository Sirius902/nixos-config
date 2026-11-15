{config, ...}: {
  sops.secrets.srcdsExtraCommandLine = {};

  my.microvms.synergyds = {
    vcpu = 2;
    memory = 4096;
    ports = {
      tcp = [27015];
      udp = [27015];
    };
    oomScoreAdjust = 800;
    data = {
      dataset = "data/srv/synergyds";
      path = "/media/data/srv/synergyds";
    };
    secrets.srcdsExtraCommandLine = config.sops.secrets.srcdsExtraCommandLine.path;
    guest.services.synergyds = {
      enable = true;
      insecure = true;
      extraCommandLineFile = "/run/credstore/srcdsExtraCommandLine";
    };
  };
}
