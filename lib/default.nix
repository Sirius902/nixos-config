{inputs}: let
  nixpkgsConfig = {
    overlays = import ../overlays/default.nix {inherit inputs;};
    config = {
      allowUnfree = true;
    };
  };
in {
  inherit nixpkgsConfig;

  pkgsFor = system:
    import inputs.nixpkgs ({inherit system;} // nixpkgsConfig);

  nixosSystem = {
    host,
    setHostName ? true,
    extraModules ? [],
  }:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules =
        [
          (../. + "/hosts/${host}/configuration.nix")

          ({lib, ...}: {
            networking.hostName = lib.mkIf setHostName host;
            nixpkgs = nixpkgsConfig;
          })
        ]
        ++ extraModules;
    };

  darwinSystem = {
    host,
    extraModules ? [],
  }:
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = {inherit inputs;};
      modules =
        [
          (../. + "/hosts/${host}/configuration.nix")

          {
            nixpkgs = nixpkgsConfig;
          }
        ]
        ++ extraModules;
    };
}
