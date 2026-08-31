{inputs}: let
  inherit (inputs) self;
in {
  nixpkgsConfig = system: {
    inherit system;
    overlays = import ../overlays/default.nix {inherit inputs;};
    config = {
      allowUnfree = true;
    };
  };

  nixosSystem = {
    system,
    host,
    setHostName ? true,
    extraModules ? [],
  }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules =
        [
          (../. + "/hosts/${host}/configuration.nix")

          ({lib, ...}: {
            networking.hostName = lib.mkIf setHostName host;
            nixpkgs.pkgs = import inputs.nixpkgs (self.lib.nixpkgsConfig system);
          })
        ]
        ++ extraModules;
    };

  darwinSystem = {
    system,
    host,
    extraModules ? [],
  }:
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules =
        [
          (../. + "/hosts/${host}/configuration.nix")

          {
            nixpkgs.pkgs = import inputs.nixpkgs (self.lib.nixpkgsConfig system);
          }
        ]
        ++ extraModules;
    };
}
