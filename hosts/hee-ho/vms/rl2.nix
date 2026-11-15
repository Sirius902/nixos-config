{
  my.microvms.rl2 = {
    vcpu = 8;
    memory = 11264; # MiB: -Xmx8G heap + ~2 GiB JVM overhead for 270 mods + guest
    ports = {
      tcp = [25565];
      udp = [24454]; # Simple Voice Chat
    };
    oomScoreAdjust = 1000;
    data = {
      dataset = "data/mc/rl2";
      path = "/media/data/mc/servers/rl2";
      snapshots = true;
    };
    guest.services.minecraft-servers.servers.rl2 = {};
  };
}
