{ pkgs, ... }:

{
  imports = [
    ./desktop-common.nix
  ];

  boot.zfs.extraPools = [ "futomaki" "kappamaki" ];

  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [
      mozc
    ];
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-terminal # Console
    epiphany # Web Browser
    geary # Email Viewer
  ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
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

  hardware = {
    openrazer = {
      enable = true;
      batteryNotifier.enable = false;
      syncEffectsEnabled = true;
    };
    xpadneo.enable = true;
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [
          (pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd
        ];
      };
    };
  };
  programs.virt-manager.enable = true;

  users.users.chris.extraGroups = [ "libvirtd" "openrazer" ];

  programs = {
    firefox.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };
  };

  services.udev.extraRules = ''
    #GameCube Controller Adapter
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", TAG+="uaccess"
  '';

  environment.systemPackages = with pkgs; [
    discord
    gimp
    inkscape
    gkraken
    keepassxc
    openrazer-daemon
    polychromatic
    (prismlauncher.override {
      jdks = [
        temurin-bin-21
        temurin-bin-8
        temurin-bin-17
      ];
    })
    spotify
    sticky
    vlc
    xivlauncher
    zed-editor
    qemu # Workaround for libvirtd efi not working.
    virtiofsd # For virtio support in QEMU.
  ];
}
