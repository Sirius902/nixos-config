{lib, ...}: {
  imports = [./sirius-lee.nix];

  my.vfio = {
    amd.enable = lib.mkForce false;
    intel.enable = true;
  };

  my.rnnoise.micNodeName = lib.mkForce "alsa_input.usb-HP__Inc_HyperX_SoloCast-00.iec958-stereo";
}
