{
  config,
  pkgs,
  ...
}: {
  fileSystems."/srv/shares" = {
    device = "/dev/disk/by-label/SHARES";
    fsType = "exfat";
    options = [
      "uid=${toString config.users.users.smbuser.uid}"
      "gid=${toString config.users.groups.users.gid}"
      "umask=002"
      "noatime"
      "nofail"
    ];
  };

  users.users.smbuser = {
    isSystemUser = true;
    uid = 994;
    description = "Samba service user";
    group = "users";
    home = "/var/lib/samba";
    createHome = true;
    shell = pkgs.shadow;
  };

  # NOTE(Sirius902) Windows clients may need to run the below commands to be able to connect because Microsoft sucks.
  # ```pwsh
  # Set-SmbClientConfiguration -EnableInsecureGuestLogons $true -Force
  # Set-SmbClientConfiguration -RequireSecuritySignature $false -Force
  # ```
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = config.networking.hostName;
        "netbios name" = config.networking.hostName;
        "security" = "user";
        # note: localhost is the ipv6 localhost ::1
        "hosts allow" = "192.168.1.0/24 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      "Public" = {
        "path" = "/srv/shares/Public";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "smbuser";
        "force group" = "users";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/shares/Public 0755 smbuser users"
  ];

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  services.avahi = {
    publish.enable = true;
    publish.userServices = true;
    # ^^ Needed to allow samba to automatically register mDNS records (without the need for an `extraServiceFile`
    nssmdns4 = true;
    # ^^ Not one hundred percent sure if this is needed- if it aint broke, don't fix it
    enable = true;
    openFirewall = true;
  };

  networking.firewall.enable = true;
  networking.firewall.allowPing = true;
}
