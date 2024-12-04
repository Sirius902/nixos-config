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
    # disko = {
    #   url = "github:nix-community/disko";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
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

  outputs = { nixpkgs, nixpkgs-stable, nix-darwin, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = { pkgs, ... }: with pkgs; {
        formatter = nixpkgs-fmt;
        devShells.default = mkShell {
          packages = [ just ];
        };
      };

      flake = {
        nixosConfigurations =
          let
            system = "x86_64-linux";
            pkgs = import nixpkgs {
              inherit system;
              overlays = [
                inputs.nix-nvim-config.overlays.default
              ];
              config = {
                allowUnfree = true;
                permittedInsecurePackages = [
                  # FUTURE(Sirius902) Required by scarab
                  "dotnet-runtime-6.0.36"
                  "dotnet-sdk-6.0.428"
                  "dotnet-sdk-wrapped-6.0.428"
                  # FUTURE(Sirius902) Required by jetbrains.rider
                  "dotnet-sdk-7.0.410"
                ];
              };
            };
            home-manager = inputs.home-manager.nixosModules;

            inherit (pkgs) lib;

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
            nixlee =
              let
                args = lib.attrsets.unionOfDisjoint inputs {
                  hostname = "nixlee";
                  hostId = "ff835154";
                  isDesktop = true;
                };
              in
              nixpkgs.lib.nixosSystem {
                inherit pkgs system;
                specialArgs = args;
                modules = [
                  ./configuration.nix
                  ./hosts/nixlee.nix
                  (hw-config-or ./hardware/nixlee.nix)
                  ./modules/nvidia.nix
                  home-manager.home-manager
                  {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.extraSpecialArgs = args;
                    home-manager.users.chris = import ./home.nix;
                  }
                ];
              };

            nixtower =
              let
                args = lib.attrsets.unionOfDisjoint inputs {
                  hostname = "nixtower";
                  hostId = "1a14084a";
                  isDesktop = true;
                };
              in
              nixpkgs.lib.nixosSystem {
                inherit pkgs system;
                specialArgs = args;
                modules =
                  [
                    ./configuration.nix
                    ./hosts/nixtower.nix
                    (hw-config-or ./hardware/nixtower.nix)
                    ./modules/nvidia.nix
                    home-manager.home-manager
                    {
                      home-manager.useGlobalPkgs = true;
                      home-manager.useUserPackages = true;
                      home-manager.extraSpecialArgs = args;
                      home-manager.users.chris = import ./home.nix;
                    }
                  ];
              };

            hee-ho =
              let
                args = lib.attrsets.unionOfDisjoint inputs-stable {
                  hostname = "hee-ho";
                  hostId = "b0e08309";
                  isDesktop = false;
                };
              in
              nixpkgs-stable.lib.nixosSystem {
                inherit system;
                pkgs = pkgs-stable;
                specialArgs = args;
                modules =
                  [
                    ./configuration.nix
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
                      home-manager.extraSpecialArgs = args;
                      home-manager.users.chris = import ./home.nix;
                    }
                  ];
              };

            nixpad =
              let
                args = lib.attrsets.unionOfDisjoint inputs {
                  hostname = "nixpad";
                  hostId = "1c029249";
                  isDesktop = true;
                };
              in
              nixpkgs.lib.nixosSystem {
                inherit pkgs system;
                specialArgs = args;
                modules =
                  [
                    /configuration.nix
                    ./hosts/nixpad.nix
                    (hw-config-or ./hardware/nixpad.nix)
                    home-manager.home-manager
                    {
                      home-manager.useGlobalPkgs = true;
                      home-manager.useUserPackages = true;
                      home-manager.extraSpecialArgs = args;
                      home-manager.users.chris = import ./home.nix;
                    }
                  ];
              };

            qemu =
              let
                args = lib.attrsets.unionOfDisjoint inputs {
                  hostname = "vm";
                  hostId = "1763015d";
                  isDesktop = true;
                };
              in
              nixpkgs.lib.nixosSystem {
                inherit pkgs system;
                specialArgs = args;
                modules =
                  [
                    ./configuration.nix
                    ./hosts/qemu.nix
                    (hw-config-or ./hardware/qemu.nix)

                    # TODO: This conflicts with the manual hardware config. Decide which to use.
                    # disko.nixosModules.disko
                    # ./disk-config.nix
                    # { disko.devices.disk.primary.device = "/dev/vda"; }

                    home-manager.home-manager
                    {
                      home-manager.useGlobalPkgs = true;
                      home-manager.useUserPackages = true;
                      home-manager.extraSpecialArgs = args;
                      home-manager.users.chris = import ./home.nix;
                    }
                  ];
              };

            qemu-server =
              let
                args = lib.attrsets.unionOfDisjoint inputs-stable {
                  hostname = "vm-server";
                  hostId = "f531a5e3";
                  isDesktop = false;
                };
              in
              nixpkgs-stable.lib.nixosSystem {
                inherit system;
                pkgs = pkgs-stable;
                specialArgs = args;
                modules =
                  [
                    ./configuration.nix
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
                      home-manager.extraSpecialArgs = args;
                      home-manager.users.chris = import ./home.nix;
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

            args = inputs;

            darwinConfig = nix-darwin.lib.darwinSystem {
              inherit system pkgs;
              specialArgs = args;
              modules = [
                ./darwin/configuration.nix

                home-manager.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = args;
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
    };
}
