{
  # NOTE(Sirius902) Make sure you're logged out of the desktop environment on the target
  # machine otherwise you'll arrive at a black screen.
  services.xrdp = {
    enable = true;
    openFirewall = true;
  };
}
