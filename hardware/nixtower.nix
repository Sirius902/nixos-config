# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
      ../modules/vfio.nix
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "thunderbolt" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "zroot";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "zroot/home";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "zroot/nix";
      fsType = "zfs";
    };

  fileSystems."/persist" =
    { device = "zroot/persist";
      fsType = "zfs";
    };

  fileSystems."/media/vm" =
    { device = "zroot/vm";
      fsType = "zfs";
    };

  fileSystems."/media/vm/shared" =
    { device = "zroot/vm/shared";
      fsType = "zfs";
    };

  fileSystems."/media/steam" =
    { device = "zroot/steam";
      fsType = "zfs";
    };

  fileSystems."/efi" =
    { device = "/dev/disk/by-uuid/DB2C-20CA";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  fileSystems."/home/chris/.local/share/openmw" =
    { device = "zroot/home/openmw";
      fsType = "zfs";
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp111s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp112s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
