{pkgs, ...}: {
  # Razer Nommo V2 X reports a dB range of -2837 to -6, causing PipeWire's
  # dB-based volume mapping to be inaudible below ~33%. Use software volume
  # and ignore the broken dB scale. ALSA hardware mixer must be at 100%.
  boot.extraModprobeConfig = "options snd-usb-audio quirk_flags=0x1532:0x055e:0x8000000";

  environment.etc."wireplumber/wireplumber.conf.d/99-nommo-volume-fix.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          { device.name = "~alsa_card.*Razer_Nommo*" }
        ]
        actions = {
          update-props = {
            api.alsa.ignore-dB = true
            api.alsa.soft-mixer = true
          }
        }
      }
    ]
  '';

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="sound", ATTRS{idVendor}=="1532", ATTRS{idProduct}=="055e", RUN+="${pkgs.alsa-utils}/bin/amixer -c $attr{number} sset PCM 100%%"
  '';
}
