{
  description = "nixlee flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+ssh://git@github.com/Sirius902/nixos-secrets.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, ... }@inputs:
    let
      systems = [ "x86_64-linux" ];
      home-manager = inputs.home-manager.nixosModules;
    in
    {
      formatter = nixpkgs.lib.attrsets.genAttrs systems (system:
        nixpkgs.legacyPackages.${system}.nixpkgs-fmt
      );

      packages = nixpkgs.lib.attrsets.genAttrs systems (system: {
        default =
          let
            pkgs = import nixpkgs { inherit system; };
          in
          pkgs.mkShell {
            packages = [
              pkgs.just
              pkgs.mkpasswd
            ];
          };
      });

      nixosConfigurations = {
        nixlee = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            hostname = "nixlee";
            hostId = "ff835154";
          };
          modules = [
            ./configuration.nix
            ./hosts/nixlee.nix
            ./modules/nvidia.nix
            home-manager.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.chris = import ./home.nix {
                inherit inputs;
                isDesktop = true;
              };
            }
          ];
        };

        vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            hostname = "vm";
            hostId = "1763015d";
          };
          modules = [
            ./configuration.nix
            ./hosts/vm.nix
            ./hosts/desktop-common.nix
            disko.nixosModules.disko

            ./disk-config.nix

            home-manager.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.chris = import ./home.nix {
                inherit inputs;
                isDesktop = true;
              };
            }
          ];
        };

        server = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            hostname = "nixlee-server";
            # TODO: Change these.
            hostId = "1763015d";
          };
          modules = [
            ./configuration.nix
            ./hosts/server.nix
            home-manager.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.chris = import ./home.nix {
                inherit inputs;
                isDesktop = false;
              };
            }
          ];
        };

        vm-server = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            hostname = "vm-server";
            # TODO: Change these.
            hostId = "1763015d";
          };
          modules = [
            ./configuration.nix
            ./hosts/vm.nix
            disko.nixosModules.disko

            ./disk-config.nix

            home-manager.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.chris = import ./home.nix {
                inherit inputs;
                isDesktop = false;
              };
            }
          ];
        };
      };
    };
}
