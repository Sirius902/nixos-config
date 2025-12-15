{inputs}: {
  nixosSystem = {
    system,
    host,
    nixpkgs ? inputs.nixpkgs,
    setHostName ? true,
    extraModules ? [],
  }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules =
        [
          (../. + "/hosts/${host}/configuration.nix")

          ({lib, ...}: {
            networking.hostName = lib.mkIf setHostName host;
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
        ]
        ++ extraModules;
    };
}
