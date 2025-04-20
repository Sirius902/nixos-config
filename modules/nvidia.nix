{
  config,
  pkgs,
  lib,
  ...
}: {
  hardware.graphics = {
    enable = true;
    extraPackages = [pkgs.nvidia-vaapi-driver];
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    # TODO(Sirius902) Switch back to open once there is a tagged release.
    # https://github.com/NVIDIA/open-gpu-kernel-modules
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "570.144";
      sha256_64bit = "sha256-wLjX7PLiC4N2dnS6uP7k0TI9xVWAJ02Ok0Y16JVfO+Y=";
      sha256_aarch64 = lib.fakeSha256;
      openSha256 = lib.fakeSha256;
      settingsSha256 = "sha256-VcCa3P/v3tDRzDgaY+hLrQSwswvNhsm93anmOhUymvM=";
      persistencedSha256 = lib.fakeSha256;
    };
  };
}
