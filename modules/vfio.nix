{
  boot.kernelParams = ["intel_iommu=on" "iommu=pt"];
  boot.kernelModules = ["vfio-pci"];
}
