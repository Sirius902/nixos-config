{
  boot.kernelParams = ["intel_iommu=on" "iommu=pt"];
  boot.kernelModules = ["vfio-pci" "vfio" "vfio_iommu_type1"];

  # NOTE(Sirius902) Should be `softdep nvidia pre: vfio-pci` for NVIDIA.
  # Pick the correct one based on NixOS options?
  boot.extraModprobeConfig = ''
    softdep drm pre: vfio-pci
  '';

  # NOTE(Sirius902) For AMD it seems you must set some weird KVM settings to
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
