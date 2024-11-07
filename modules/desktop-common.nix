{ pkgs, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [
      mozc
    ];
  };

  services.openssh.enable = true;

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

    extraConfig.pipewire-pulse = {
      # Fixes Wine audio crackling.
      # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/3098#note_1823699
      "20-pulse-properties" = {
        "pulse.properties" = {
          "pulse.min.req" = "256/48000";
          "pulse.min.frag" = "256/48000";
          "pulse.min.quantum" = "256/48000";
        };
      };
    };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  hardware = {
    openrazer = {
      enable = true;
      batteryNotifier.enable = false;
      syncEffectsEnabled = true;
    };
    xpadneo.enable = true;
    keyboard.zsa.enable = true;
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
    # TODO: Use hooks.qemu instead of symlinking in libvirtd service.
    #hooks.qemu = { };
  };
  programs.virt-manager.enable = true;

  systemd.services.libvirtd = {
    preStart = ''
      mkdir -p /var/lib/libvirt/hooks/
      mkdir -p /var/lib/libvirt/hooks/qemu.d/win11-vfio/prepare/begin/
      mkdir -p /var/lib/libvirt/hooks/qemu.d/win11-vfio/release/end/

      ln -sf /persist/qemu-hooks/qemu /var/lib/libvirt/hooks/qemu
      ln -sf /persist/qemu-hooks/kvm.conf /var/lib/libvirt/hooks/kvm.conf
      ln -sf /persist/qemu-hooks/vfio/start.sh /var/lib/libvirt/hooks/qemu.d/win11-vfio/prepare/begin/start.sh
      ln -sf /persist/qemu-hooks/vfio/stop.sh /var/lib/libvirt/hooks/qemu.d/win11-vfio/release/end/stop.sh
    '';
  };

  users.users.chris.extraGroups = [ "libvirtd" "openrazer" ];

  programs = {
    firefox.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };
    gamescope.enable = true;
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    noto-fonts-cjk-sans
  ];

  services.udev.extraRules = ''
    #GameCube Controller Adapter
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", TAG+="uaccess"
  '';

  # For wgnord
  services.resolved.enable = true;

  environment.systemPackages = with pkgs; [
    dolphin-emu-beta
    gimp
    gparted
    inkscape
    jetbrains.idea-community
    gkraken
    hunspell
    keepassxc
    keymapp
    krita
    libreoffice-qt
    lunar-client
    (wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-pipewire-audio-capture
      ];
    })
    nautilus-python # Required for Open in WezTerm.
    openmw
    openrazer-daemon
    polychromatic
    (prismlauncher.override {
      jdks = [
        temurin-bin-21
        temurin-bin-8
        temurin-bin-17
      ];
    })
    protontricks
    scarab
    spotify
    sticky
    transmission_4-qt
    vesktop # Discord alternative with better support on Linux.
    vlc
    vscodium
    wgnord
    wl-clipboard
    xivlauncher
    zed-editor
    qdirstat
    qemu # Workaround for libvirtd efi not working.
    virtiofsd # For virtio support in QEMU.
    wineWowPackages.stable
    winetricks
    xclip
  ];
}
