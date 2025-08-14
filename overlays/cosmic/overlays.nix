let
  dir = builtins.readDir ./pkgs;

  matches =
    builtins.filter (m: m != null)
    (map (
      f:
        if dir.${f} == "regular"
        then builtins.match "^(.*)\\.nix$" f
        else null
    ) (builtins.attrNames dir));
in
  builtins.listToAttrs (map (m: {
      name = builtins.head m;
      value = import (./pkgs + "/${builtins.head m}.nix");
    })
    matches)
