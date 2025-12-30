final: prev: let
  pkgs = import ./all-packages.nix {
    pkgs = final;
  };
in
  pkgs
  // {
    ghidra-extensions =
      prev.ghidra-extensions
      // {
        inherit
          (pkgs)
          gamecube-loader
          xex-loader-wv
          ;
      };
  }
