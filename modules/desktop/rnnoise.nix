{
  config,
  lib,
  pkgs,
  ...
}: let
  micNodeName = config.my.rnnoise.micNodeName;
in {
  options.my.rnnoise.micNodeName = with lib;
    mkOption {
      type = types.nullOr types.str;
      description = "The PipeWire node name of the microphone to apply rnnoise to.";
      example = "alsa_input.usb-HP__Inc_HyperX_SoloCast-00.iec958-stereo";
      default = null;
    };

  config = lib.mkIf (micNodeName != null) {
    services.pipewire.extraConfig.pipewire."99-input-denoising" = {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Noise Canceling source";
            "media.name" = "Noise Canceling source";

            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "rnnoise";
                  plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                  label = "noise_suppressor_mono";
                  control = {
                    "VAD Threshold (%)" = 95.0;
                    "VAD Grace Period (ms)" = 200;
                    "Retroactive VAD Grace (ms)" = 0;
                  };
                }
              ];
            };

            "capture.props" = {
              "node.name" = "capture.rnnoise_source";
              "node.passive" = true;
              "audio.rate" = 48000;
              "target.object" = micNodeName;
            };

            "playback.props" = {
              "node.name" = "rnnoise_source";
              "media.class" = "Audio/Source";
              "audio.rate" = 48000;
            };
          };
        }
      ];
    };
  };
}
