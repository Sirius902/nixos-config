{
  services.pipewire.extraConfig.pipewire."92-crackle-fix" = {
    "context.properties" = {
      "default.clock.quantum" = 1024; # default 1024
      "default.clock.min-quantum" = 1024; # default 32
      "default.clock.max-quantum" = 2048; # default 2048
    };
    "pulse.properties" = {
      "pulse.min.req" = "256/48000";
      "pulse.min.frag" = "256/48000";
      "pulse.min.quantum" = "256/48000";
    };
  };
}
