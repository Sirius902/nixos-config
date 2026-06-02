{pkgs, ...}: {
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.pop-icon-theme;
    name = "Pop";
    size = 16;
  };
}
