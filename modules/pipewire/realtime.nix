{
  services.pipewire.extraConfig.pipewire."92-realtime" = {
    "context.properties" = {
      "default.realtime" = true;
      "default.realtime.priority" = 88;
      "default.nice.level" = -19;
    };
  };
}
