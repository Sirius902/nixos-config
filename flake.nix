{
  description = "nixlee flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+ssh://git@github.com/Sirius902/nixos-secrets.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim-config = {
      url = "github:Sirius902/nixvim-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, disko, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake = {
        nixosConfigurations =
          let
            home-manager = inputs.home-manager.nixosModules;
          in
          {
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

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = { pkgs, system, ... }: {
        formatter = pkgs.nixpkgs-fmt;
        packages.default = pkgs.mkShell {
          packages = [ pkgs.just ];
        };
      };
    };
}
