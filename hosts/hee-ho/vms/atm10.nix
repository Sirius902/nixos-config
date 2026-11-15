{pkgs, ...}: {
  my.microvms.atm10 = {
    vcpu = 8;
    memory = 21504; # MiB: -Xmx16G heap + ~5 GiB JVM overhead for the pack + guest
    ports.tcp = [25565];
    oomScoreAdjust = 1000;
    data = {
      dataset = "data/mc/atm10";
      path = "/media/data/mc/servers/atm10";
      snapshots = true;
    };
    guest.services.minecraft-servers.servers.atm10.jdk = pkgs.graalvmPackages.graalvm-oracle;
  };
}
