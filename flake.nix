{
  description = "nixlee flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-stable.url = "github:nixos/nixpkgs?ref=nixos-24.05";
    home-manager-stable = {
      url = "github:nix-community/home-manager?ref=release-24.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
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
    nix-nvim-config = {
      url = "github:Sirius902/nix-nvim-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-stable, disko, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake = {
        nixosConfigurations =
          let
            system = "x86_64-linux";
            pkgs = import nixpkgs {
              inherit system;
              overlays = [
                inputs.nix-nvim-config.overlays.default
              ];
              config.allowUnfree = true;
            };
            home-manager = inputs.home-manager.nixosModules;
            pkgs-stable = import nixpkgs-stable {
              inherit system;
              overlays = [
                inputs.nix-nvim-config.overlays.default
              ];
              config.allowUnfree = true;
            };
            home-manager-stable = inputs.home-manager-stable.nixosModules;
            inputs-stable = inputs // { nixpkgs = nixpkgs-stable; home-manager = home-manager-stable; };
            hw-config-or = cfg:
              if (builtins.pathExists ./hardware-configuration.nix) then
                ./hardware-configuration.nix
              else
                cfg;
          in
          {
            nixlee = nixpkgs.lib.nixosSystem {
              inherit pkgs system;
              specialArgs = {
                inherit inputs;
                hostname = "nixlee";
                hostId = "ff835154";
              };
              modules = [
                ./configuration.nix
                ./hosts/nixlee.nix
                (hw-config-or ./hardware/nixlee.nix)
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

            hee-ho = nixpkgs-stable.lib.nixosSystem {
              inherit system;
              pkgs = pkgs-stable;
              specialArgs = {
                inputs = inputs-stable;
                hostname = "hee-ho";
                hostId = "b0e08309";
              };
              modules = [
                ./configuration.nix
                ./hosts/server.nix
                (hw-config-or ./hardware/hee-ho.nix)

                disko.nixosModules.disko
                ./disk-config.nix
                { disko.devices.disk.primary.device = "/dev/nvme2n1"; }

                home-manager-stable.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.users.chris = import ./home.nix {
                    inputs = inputs-stable;
                    isDesktop = false;
                  };
                }
              ];
            };

            qemu = nixpkgs.lib.nixosSystem {
              inherit pkgs system;
              specialArgs = {
                inherit inputs;
                hostname = "vm";
                hostId = "1763015d";
              };
              modules = [
                ./configuration.nix
                ./hosts/qemu.nix
                (hw-config-or ./hardware/qemu.nix)
                ./modules/desktop-common.nix

                disko.nixosModules.disko
                ./disk-config.nix
                { disko.devices.disk.primary.device = "/dev/vda"; }

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

            qemu-server = nixpkgs-stable.lib.nixosSystem {
              inherit system;
              pkgs = pkgs-stable;
              specialArgs = {
                inputs = inputs-stable;
                hostname = "vm-server";
                # TODO: Change these.
                hostId = "1763015d";
              };
              modules = [
                ./configuration.nix
                ./hosts/server.nix
                ./hosts/qemu.nix
                (hw-config-or ./hardware/qemu.nix)

                disko.nixosModules.disko
                ./disk-config.nix
                { disko.devices.disk.primary.device = "/dev/vda"; }

                home-manager-stable.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.users.chris = import ./home.nix {
                    inputs = inputs-stable;
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
