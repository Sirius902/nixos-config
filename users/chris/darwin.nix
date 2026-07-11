{
  my.homeUsers = ["chris"];

  users.users.chris = {
    name = "chris";
    home = "/Users/chris";
  };

  nix.settings.trusted-users = ["chris"];

  home-manager.users.chris = import ./home/default.nix;
}
