{
  lib,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;

    signing = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = true;
      format = "ssh";
    };

    settings = {
      user = {
        name = "Sirius902";
        email = "10891979+Sirius902@users.noreply.github.com";
      };
      init.defaultBranch = "main";
    };
  };
}
