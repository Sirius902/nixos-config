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
      type = lib.types.nullOr (lib.types.enum ["cosmic" "gnome" "kde" "niri"]);
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
          sansSerif = ["DejaVu Sans" "Noto Sans CJK JP"];
          serif = ["DejaVu Serif" "Noto Serif CJK JP"];
          monospace = ["DejaVu Sans Mono" "Noto Sans Mono CJK JP"];
        };

        # GTK and Qt ask for GNOME's Adwaita Sans, which isn't installed;
        # fontconfig files it under system-ui, whose list ranks Noto Sans CJK KR
        # ahead of the sans-serif defaults.
        localConf = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            <alias>
              <family>system-ui</family>
              <prefer><family>sans-serif</family></prefer>
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
