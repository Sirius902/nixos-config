{
  services.pipewire.extraConfig.pipewire."92-low-latency" = {
    "context.properties" = {
      "default.clock.rate" = 48000;
      "default.clock.quantum" = 128;
      "default.clock.min-quantum" = 128;
      "default.clock.max-quantum" = 128;
    };
  };

  services.pipewire.extraConfig.pipewire-pulse."92-low-latency" = {
    context.modules = [
      {
        name = "libpipewire-module-protocol-pulse";
        args = {
          pulse.min.req = "128/48000";
          pulse.default.req = "128/48000";
          pulse.max.req = "128/48000";
          pulse.min.quantum = "128/48000";
          pulse.max.quantum = "128/48000";
        };
      }
    ];
    stream.properties = {
      node.latency = "128/48000";
      resample.quality = 1;
    };
  };
}
