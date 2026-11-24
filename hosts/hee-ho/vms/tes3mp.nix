{config, ...}: {
  sops.secrets.tes3mpPassword = {};

  my.microvms.tes3mp = {
    vcpu = 2;
    memory = 1024;
    ports.udp = [25565];
    egress = "none";
    oomScoreAdjust = 500;
    data = {
      dataset = "data/srv/tes3mp";
      path = "/media/data/srv/tes3mp";
      snapshots = true;
    };
    secrets.tes3mpPassword = config.sops.secrets.tes3mpPassword.path;
    guest.services.tes3mp-server = {
      enable = true;
      passwordFile = "/run/credstore/tes3mpPassword";
    };
  };
}
