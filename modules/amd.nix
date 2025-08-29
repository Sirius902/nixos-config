{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = ["amdgpu"];

  # FUTURE(Sirius902) See if there's any updates on this and if this is even the problem I'm having...
  # https://gitlab.freedesktop.org/drm/amd/-/issues/4356
}
