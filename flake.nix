{
  description = "nixlee flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # TODO: Switch back once ZFS 2.3.0 stable comes out.
    #nixpkgs-stable.url = "github:nixos/nixpkgs?ref=nixos-24.05";
    nixpkgs-stable.url = "github:nixos/nixpkgs?rev=32e940c7c420600ef0d1ef396dc63b04ee9cad37";
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
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-stable, nix-darwin, disko, flake-parts, ... }@inputs:
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
              modules = let isDesktop = true; in
                [
                  (import ./configuration.nix { inherit isDesktop; })
                  ./hosts/nixlee.nix
                  (hw-config-or ./hardware/nixlee.nix)
                  ./modules/nvidia.nix
                  home-manager.home-manager
                  {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.users.chris = import ./home.nix {
                      inherit inputs isDesktop;
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
              modules = let isDesktop = false; in
                [
                  (import ./configuration.nix { inherit isDesktop; })
                  ./hosts/server.nix
                  ./hosts/hee-ho.nix
                  (hw-config-or ./hardware/hee-ho.nix)

                  # TODO: This conflicts with the manual hardware config. Decide which to use.
                  # disko.nixosModules.disko
                  # ./disk-config.nix
                  # { disko.devices.disk.primary.device = "/dev/nvme0n1"; }

                  home-manager-stable.home-manager
                  {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.users.chris = import ./home.nix {
                      inherit isDesktop;
                      inputs = inputs-stable;
                    };
                  }
                ];
            };

            nixpad = nixpkgs.lib.nixosSystem {
              inherit pkgs system;
              specialArgs = {
                inherit inputs;
                hostname = "nixpad";
                hostId = "1c029249";
              };
              modules = let isDesktop = true; in
                [
                  (import ./configuration.nix { inherit isDesktop; })
                  ./hosts/nixpad.nix
                  (hw-config-or ./hardware/nixpad.nix)
                  home-manager.home-manager
                  {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.users.chris = import ./home.nix {
                      inherit inputs isDesktop;
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
              modules = let isDesktop = true; in
                [
                  (import ./configuration.nix { inherit isDesktop; })
                  ./hosts/qemu.nix
                  (hw-config-or ./hardware/qemu.nix)
                  ./modules/desktop-common.nix

                  # TODO: This conflicts with the manual hardware config. Decide which to use.
                  # disko.nixosModules.disko
                  # ./disk-config.nix
                  # { disko.devices.disk.primary.device = "/dev/vda"; }

                  home-manager.home-manager
                  {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.users.chris = import ./home.nix {
                      inherit inputs isDesktop;
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
                hostId = "f531a5e3";
              };
              modules = let isDesktop = false; in
                [
                  (import ./configuration.nix { inherit isDesktop; })
                  ./hosts/server.nix
                  ./hosts/qemu.nix
                  (hw-config-or ./hardware/qemu.nix)

                  # TODO: This conflicts with the manual hardware config. Decide which to use.
                  # disko.nixosModules.disko
                  # ./disk-config.nix
                  # { disko.devices.disk.primary.device = "/dev/vda"; }

                  home-manager-stable.home-manager
                  {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.users.chris = import ./home.nix {
                      inherit isDesktop;
                      inputs = inputs-stable;
                    };
                  }
                ];
            };
          };

        darwinConfigurations =
          let
            system = "aarch64-darwin";
            pkgs = import nixpkgs {
              inherit system;
              overlays = [
                inputs.nix-nvim-config.overlays.default
              ];
              config.allowUnfree = true;
            };
            home-manager = inputs.home-manager.darwinModules;

            darwinConfig = nix-darwin.lib.darwinSystem {
              inherit system pkgs;
              specialArgs = inputs;
              modules = [
                ./darwin/configuration.nix

                home-manager.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.users.chris = import ./darwin/home.nix;
                }
              ];
            };
          in
          {
            # Build darwin flake using:
            # $ darwin-rebuild build --flake .#Tralsebook
            "Tralsebook" = darwinConfig;
            "The-Rekening" = darwinConfig;
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
