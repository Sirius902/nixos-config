{pkgs, ...}: {
  virtualisation.docker = {
    enable = true;

    # FUTURE(Sirius902) Networking seems to be broken with rootless docker...
    # rootless = {
    #   enable = true;
    #   setSocketVariable = true;
    # };
  };

  # FUTURE(Sirius902) Remove if rootless docker.
  users.users.chris.extraGroups = ["docker"];

  environment.systemPackages = [
    pkgs.docker-compose
  ];
}
