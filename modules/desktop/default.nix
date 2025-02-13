{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [../disable-hsp.nix];

  services.openssh.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  programs.firefox.enable = true;

  fonts.packages = with pkgs; [
    (
      if (lib.versionAtLeast config.system.nixos.release "24.11")
      then nerd-fonts.jetbrains-mono
      else (nerdfonts.override {fonts = ["JetBrainsMono"];})
    )

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
    vscodium
    zed-editor
  ];
}
