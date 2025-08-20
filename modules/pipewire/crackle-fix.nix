{
  services.pipewire.wireplumber.extraConfig."92-hdmi-crackle-fix" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          {"node.nick" = "DELL S2722DGM";}
        ];
        actions.update-props = {
          "api.alsa.headroom" = 1024;
        };
      }
    ];
  };
}
