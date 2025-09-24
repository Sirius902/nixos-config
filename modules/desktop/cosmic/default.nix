{pkgs, ...}: {
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  services.desktopManager.cosmic.xwayland.enable = true;

  environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;

  environment.systemPackages = [pkgs.gnome-system-monitor];

  # TODO(Sirius902) We probably want this for GNOME too?
  # Reset dconf changes made upon launching a KDE session.
  systemd.user.services.reset-dconf-cosmic = {
    enable = true;
    before = ["cosmic-session.target"];
    wantedBy = ["graphical-session.target"];
    description = "Reset dconf for COSMIC";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = let
        script = pkgs.writeShellApplication {
          name = "reset-dconf-cosmic";
          runtimeInputs = [pkgs.dconf];
          text = ''
            dconf reset -f /org/gnome/desktop/interface/
            dconf reset /org/gnome/desktop/sound/theme-name
            dconf reset /org/gnome/desktop/wm/preferences/button-layout
          '';
        };
      in ''${script}/bin/reset-dconf-cosmic'';
    };
  };
}
