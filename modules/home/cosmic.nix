{pkgs, ...}: {
  # Fix xwayland apps not having the correct cursor.
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.cosmic-icons;
    name = "Cosmic";
    size = 16;
  };
}
