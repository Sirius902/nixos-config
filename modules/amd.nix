{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # FUTURE(Sirius902) Remove once this commit makes it to the base linuxPackages
  # https://gitlab.freedesktop.org/drm/misc/kernel/-/commit/95a16160ca1d75c66bf7a1c5e0bcaffb18e7c7fc
  my.kernelPatches = [../patches/drm-suspend-fix.patch];
}
