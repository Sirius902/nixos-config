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

    programs.appimage = {
      enable = true;
      binfmt = true;
    };

    programs.firefox = {
      enable = true;
      package = pkgs.librewolf;
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
      };
    };

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts-cjk-sans
    ];

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
    ];

    home-manager.users.chris.imports = [
      ../home/desktop.nix
      ../home/ghostty/default.nix
    ];
  };
}
