{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.desktop;
in {
  imports = [
    ./full.nix
    ./display-manager.nix
    ./rnnoise.nix
    ./cosmic/default.nix
    ./gnome/default.nix
    ./kde/default.nix
    ./i3/default.nix
    ./niri/default.nix
    ./fcitx.nix
    ./ibus.nix
    ../disable-hsp.nix
  ];

  options.my.desktop = {
    enable = lib.mkEnableOption "desktop environment";
    full = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable full desktop with gaming/dev tools.";
    };
    environment = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["cosmic" "gnome" "kde" "i3"]);
      default = null;
      description = "Desktop environment to use.";
    };
    inputMethod = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["fcitx" "ibus"]);
      default = null;
      description = "Input method framework to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    services.printing.enable = true;

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # FUTURE(Sirius902) Force SDL applications to use PulseAudio instead of
    # native PipeWire so that Discord's PulseAudio-based stream capture can
    # see their audio.
    environment.sessionVariables.SDL_AUDIODRIVER = "pulse";
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    programs.appimage = {
      enable = true;
      binfmt = true;
    };

    programs.firefox = {
      enable = true;
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
      };
    };

    fonts = {
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        noto-fonts-cjk-sans
      ];

      fontconfig = {
        defaultFonts = {
          monospace = ["JetBrainsMono Nerd Font" "Noto Sans Mono CJK JP"];
          sansSerif = ["Noto Sans" "Noto Sans CJK JP"];
          serif = ["Noto Serif" "Noto Serif CJK JP"];
          emoji = ["Noto Color Emoji"];
        };

        # Qt's gnome platform theme requests the uninstalled GNOME default UI
        # fonts by name; without a substitution the nonlatin alias rules hand
        # them to Noto Sans CJK KR.
        localConf = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            <match target="pattern">
              <test qual="any" name="family"><string>Adwaita Sans</string></test>
              <edit name="family" mode="assign" binding="same"><string>Noto Sans</string></edit>
            </match>
            <match target="pattern">
              <test qual="any" name="family"><string>Cantarell</string></test>
              <edit name="family" mode="assign" binding="same"><string>Noto Sans</string></edit>
            </match>
            <match target="pattern">
              <test qual="any" name="family"><string>Adwaita Mono</string></test>
              <edit name="family" mode="assign" binding="same"><string>JetBrainsMono Nerd Font</string></edit>
            </match>
          </fontconfig>
        '';
      };
    };

    environment.systemPackages = with pkgs; [
      chromium
      gparted
      hunspell
      imagemagick
      keepassxc
      popsicle
      qdirstat
      wl-clipboard
      xclip
      vscode
      zed-editor
    ];

    home-manager.users = lib.genAttrs config.my.homeUsers (_: {
      imports = [
        ../home/desktop.nix
        ../home/ghostty/default.nix
        ../home/mime.nix
      ];
    });
  };
}
