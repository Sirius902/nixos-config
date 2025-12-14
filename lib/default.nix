{inputs}: {
  nixosSystem = {
    system,
    host,
    nixpkgs ? inputs.nixpkgs,
    setHostName ? true,
  }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules = [
        (../. + "/hosts/${host}/configuration.nix")

        ({lib, ...}: {
          networking.hostName = lib.mkIf setHostName host;
        })
      ];
    };

  darwinSystem = {
    system,
    host,
  }:
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules = [
        (../. + "/hosts/${host}/configuration.nix")
      ];
    };
}
