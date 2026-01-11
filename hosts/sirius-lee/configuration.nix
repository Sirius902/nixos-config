{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./default.nix
    ./hardware-configuration.nix

    inputs.nixos-vfio.nixosModules.vfio
  ];

  my.vfio.enable = lib.mkForce false;

  boot.extraModprobeConfig = ''
    softdep amdgpu pre: vfio-pci
  '';

  virtualisation.libvirtd = {
    deviceACL = [
      "/dev/kvm"
      "/dev/kvmfr0"
      "/dev/kvmfr1"
      "/dev/kvmfr2"
      "/dev/shm/scream"
      "/dev/shm/looking-glass"
      "/dev/null"
      "/dev/full"
      "/dev/zero"
      "/dev/random"
      "/dev/urandom"
      "/dev/ptmx"
      "/dev/kvm"
      "/dev/kqemu"
      "/dev/rtc"
      "/dev/hpet"
      "/dev/vfio/vfio"
    ];
  };

  virtualisation.spiceUSBRedirection.enable = true;

  virtualisation.vfio = {
    enable = true;
    IOMMUType = "amd";
    devices = [
      # "1002:7550"
      # "1002:ab40"
    ];
  };

  users.groups.kvmfr = {};
  users.users.chris.extraGroups = ["kvmfr"];

  virtualisation.kvmfr = {
    enable = true;
    devices = lib.singleton {
      size = 128;
      permissions = {
        group = "kvmfr";
        mode = "0777";
      };
    };
  };
  users.users.qemu-libvirtd.group = "qemu-libvirtd";
  users.groups.qemu-libvirtd = {};

  # boot.blacklistedKernelModules = [
  #   "amdgpu"
  #   "radeon"
  # ];

  environment.systemPackages = with pkgs; [
    looking-glass-client
  ];
}
