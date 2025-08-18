{
  services.pipewire.wireplumber.extraConfig."92-hdmi-crackle-fix" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          {"node.nick" = "DELL S2722DGM";}
        ];
        actions.update-props = {
          "node.latency" = "1024/48000";
          "node.quantum" = 1024;
        };
      }
    ];
  };
}
