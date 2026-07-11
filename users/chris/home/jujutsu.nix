{
  lib,
  pkgs,
  ...
}: {
  programs.jujutsu = {
    enable = true;

    settings =
      {
        user = {
          name = "Sirius902";
          email = "10891979+Sirius902@users.noreply.github.com";
        };
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        signing = {
          behavior = "own";
          backend = "ssh";
          key = "~/.ssh/id_ed25519.pub";
        };
      };
  };
}
