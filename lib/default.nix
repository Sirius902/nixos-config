{inputs}: let
  nixpkgsConfig = {
    overlays = import ../overlays/default.nix {inherit inputs;};
    config = {
      allowUnfree = true;
    };
  };

  pkgsFor = system:
    import inputs.nixpkgs ({inherit system;} // nixpkgsConfig);
in {
  inherit nixpkgsConfig pkgsFor;

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

  # `homeManagerConfiguration` re-exports the overlays and config of the `pkgs`
  # it is handed, so `pkgsFor` is all this needs to carry `nixpkgsConfig` in.
  # `basePkgs` hands that same set to the configuration, for one that replaces
  # an attr through `_module.args.pkgs` rather than through an overlay.
  homeConfiguration = {
    home,
    system,
    extraModules ? [],
  }: let
    pkgs = pkgsFor system;
  in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs;
        basePkgs = pkgs;
      };
      modules = [(../. + "/homes/${home}/default.nix")] ++ extraModules;
    };
}
