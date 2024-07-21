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
    nix-nvim-config = {
      url = "github:Sirius902/nix-nvim-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, disko, flake-parts, ... }@inputs:
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

            hee-ho = nixpkgs.lib.nixosSystem {
              inherit pkgs system;
              specialArgs = {
                inherit inputs;
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

            qemu-server = nixpkgs.lib.nixosSystem {
              inherit pkgs system;
              specialArgs = {
                inherit inputs;
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
