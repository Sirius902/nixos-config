{lib, ...}: {
  imports = [./sirius-lee.nix];

  # TODO(Sirius902) LMAO. Remove this once the issue is fixed.
  # https://mundobytes.com/en/Linux-6%3A-16-problems-with-Asus-motherboards%3A-why-they-occur-and-how-to-mitigate-them-without-headaches/
  boot.blacklistedKernelModules = ["asus_wmi" "asus_nb_wmi"];

  my.vfio = {
    amd.enable = lib.mkForce false;
    intel.enable = true;
  };

  my.rnnoise.micNodeName = lib.mkForce "alsa_input.usb-Logitech_Yeti_GX_2428SGV014T8-00.mono-fallback";
}
