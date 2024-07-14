{
  description = "flake for nixlee";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      home-manager = inputs.home-manager.nixosModules;
      pkgs = import nixpkgs { inherit system; };
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

      defaultPackage.${system} = pkgs.mkShell {
        packages = [
          pkgs.just
          pkgs.mkpasswd
        ];
      };

      nixosConfigurations = {
        nixlee = nixpkgs.lib.nixosSystem {
          system = system;
          specialArgs = { inherit inputs; };
          modules = [
            ./configuration.nix
            ./nvidia.nix
            home-manager.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.chris = import ./home.nix {
                inputs = inputs;
              };
            }
          ];
        };

        nixlee-vm = nixpkgs.lib.nixosSystem {
          system = system;
          specialArgs = { inherit inputs; };
          modules = [
            ./configuration.nix
            ./vm.nix
            home-manager.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.chris = import ./home.nix {
                inputs = inputs;
              };
            }
          ];
        };
      };
    };
}
