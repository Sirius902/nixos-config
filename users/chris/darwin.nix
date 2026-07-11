{inputs, ...}: {
  imports = [inputs.home-manager.darwinModules.default];

  users.users.chris = {
    name = "chris";
    home = "/Users/chris";
  };

  nix.settings.trusted-users = ["chris"];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs;};
    users.chris.imports = [
      ./home/default.nix
      ../../modules/home/ghostty/default.nix
    ];
  };
}
