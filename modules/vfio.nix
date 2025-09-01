{
  config,
  lib,
  ...
}: let
  cfg = config.my.vfio;
in {
  options.my.vfio = {
    enable = lib.mkEnableOption "vfio";

    amd.enable = lib.mkEnableOption "amd";
    intel.enable = lib.mkEnableOption "intel";

    amdgpu.enable = lib.mkEnableOption "amdgpu";
    nvidia.enable = lib.mkEnableOption "nvidia";
  };

  config = lib.mkIf cfg.enable {
    boot.kernelModules = ["vfio-pci" "vfio" "vfio-iommu-type1"];

    boot.kernelParams =
      lib.optionals cfg.amd.enable ["amd_iommu=on"]
      ++ lib.optionals cfg.intel.enable ["intel_iommu=on" "iommu=pt"];

    boot.extraModprobeConfig =
      lib.optionalString cfg.amdgpu.enable ''
        softdep amdgpu pre: vfio-pci
      ''
      + lib.optionalString cfg.nvidia.enable ''
        softdep nvidia pre: vfio-pci
      '';
  };

  # NOTE(Sirius902) For AMD GPU it seems you must set some weird KVM settings to
  # get single GPU passthrough to work.
  # https://forum.level1techs.com/t/vfio-pass-through-working-on-9070xt/227194
  #
  # ```xml
  # <hyperv>
  #   <vendor_id state='on' value='myv3nd0r1d'/>
  # </hyperv>
  # <kvm>
  #   <hidden state='on'/>
  # </kvm>
  # ```
}
