{
  programs.zellij = {
    enable = true;
    extraConfig = builtins.readFile ../../dotfiles/zellij/config.kdl;
  };
}
