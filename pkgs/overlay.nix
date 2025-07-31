{nixpkgs-ghidra_11_2_1}: final: prev: let
  pkgs = import ./all-packages.nix {
    inherit nixpkgs-ghidra_11_2_1;
    pkgs = final;
  };
in
  pkgs
  // {
    ghidra-extensions =
      prev.ghidra-extensions
      // {
        gamecube-loader = pkgs.gamecube-loader;
      };
  }
