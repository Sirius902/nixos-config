{
  my.microvms.svends = {
    vcpu = 2;
    memory = 4096;
    ports = {
      tcp = [27015];
      udp = [27015];
    };
    oomScoreAdjust = 800;
    data = {
      dataset = "data/srv/svends";
      path = "/media/data/srv/svends";
    };
    guest.services.svends = {
      enable = true;
      insecure = true;
    };
  };
}
