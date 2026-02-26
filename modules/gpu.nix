{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.gpu;
in {
  options.my.gpu = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum ["amd" "nvidia"]);
    default = null;
    description = "GPU driver to configure.";
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg == "amd") {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      services.xserver.videoDrivers = ["amdgpu"];
    })
    (lib.mkIf (cfg == "nvidia") {
      programs.coolercontrol.nvidiaSupport = true;

      hardware.graphics = {
        enable = true;
        extraPackages = [pkgs.nvidia-vaapi-driver];
      };

      services.xserver.videoDrivers = ["nvidia"];

      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        powerManagement.finegrained = false;
        open = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.latest;
      };
    })
  ];
}
