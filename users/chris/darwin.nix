{inputs, ...}: {
  imports = [inputs.home-manager.darwinModules.default];

  users.users.chris = {
    name = "chris";
    home = "/Users/chris";
  };

  nix.settings.trusted-users = ["chris"];

  programs.zsh.shellInit = ''
    export SSH_AUTH_SOCK=/Users/chris/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
  '';

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
