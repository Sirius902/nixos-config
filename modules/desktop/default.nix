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
    ./proton-wineland.nix
    ./display-manager.nix
    ./rnnoise.nix
    ./cosmic/default.nix
    ./gnome/default.nix
    ./kde/default.nix
    ./i3/default.nix
    ./niri/default.nix
    ./fcitx.nix
    ./ibus.nix
  ];

  options.my.desktop = {
    enable = lib.mkEnableOption "desktop environment";
    full = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable full desktop with gaming/dev tools.";
    };
    environment = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["cosmic" "gnome" "kde" "i3" "niri"]);
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
        noto-fonts
        noto-fonts-cjk-sans
      ];

      fontconfig = {
        defaultFonts = {
          monospace = [
            "JetBrainsMono Nerd Font"
            "Noto Sans Mono CJK JP"
            "Noto Sans Symbols 2"
            "Noto Sans Math"
            "Noto Sans Symbols"
          ];
          sansSerif = ["Noto Sans" "Noto Sans CJK JP"];
          serif = ["Noto Serif" "Noto Serif CJK JP"];
          emoji = ["Noto Color Emoji"];
        };

        localConf = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            <!-- GTK and Qt's gnome platform theme request GNOME's uninstalled
                 UI font, which fontconfig classes as system-ui. Its system-ui
                 list ranks Noto Sans CJK KR ahead of the sansSerif defaults,
                 so both would take Han characters from the KR face. -->
            <alias>
              <family>system-ui</family>
              <prefer>
                ${lib.concatMapStrings (f: "<family>${f}</family>") config.fonts.fontconfig.defaultFonts.sansSerif}
              </prefer>
            </alias>
            <!-- A fallback query naming no family gets monospace weakly, and
                 defaultFonts binds the same. Fontconfig ranks language
                 coverage above a weak family match, so the symbol-only faces
                 would lose a missing glyph to any font covering the locale. -->
            <alias binding="strong">
              <family>monospace</family>
              <prefer>
                ${lib.concatMapStrings (f: "<family>${f}</family>") config.fonts.fontconfig.defaultFonts.monospace}
              </prefer>
            </alias>
          </fontconfig>
        '';
      };
    };

    # Currently for GParted, which relaunches itself through pkexec.
    security.polkit.enablePkexecWrapper = true;

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
