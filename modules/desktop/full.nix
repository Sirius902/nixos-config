{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./default.nix
    ./rnnoise.nix
  ];

  hardware = {
    keyboard.zsa.enable = true;
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
    # TODO: Use hooks.qemu instead of symlinking in libvirtd service.
    #hooks.qemu = { };
  };
  programs.virt-manager.enable = true;

  # Related https://github.com/NixOS/nixpkgs/pull/432610.
  networking.firewall.trustedInterfaces = ["virbr0"];

  environment.persistence."/persist".directories = ["/etc/libvirt"];

  users.users.chris.extraGroups = ["libvirtd"];

  programs = {
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
    coolercontrol.enable = true;
  };

  # NOTE(Sirius902) We can't use `services.udev.extraRules` here as `uaccess` won't work properly.
  # https://github.com/NixOS/nixpkgs/issues/210856
  services.udev.packages = [
    pkgs.gcfeederd
    (pkgs.writeTextFile {
      name = "switch2-gc-rules";
      text = ''
        # Nintendo GameCube Controller
        SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="057e", ATTR{idProduct}=="2073", TAG+="uaccess"
      '';
      destination = "/etc/udev/rules.d/50-switch2-gc.rules";
    })
    (pkgs.writeTextFile {
      name = "switch-rules";
      text = ''
        # Nintendo Switch
        SUBSYSTEM=="usb", ATTR{idVendor}=="0955", TAG+="uaccess"
      '';
      destination = "/etc/udev/rules.d/50-switch.rules";
    })
    (pkgs.writeTextFile {
      name = "electromodder-rules";
      text = ''
        # Electromodder Adapter V2
        SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", TAG+="uaccess"
      '';
      destination = "/etc/udev/rules.d/50-electromodder.rules";
    })
  ];

  # For wgnord
  services.resolved.enable = true;

  # melonDS LAN port
  networking.firewall.allowedTCPPorts = [7064];

  environment.systemPackages = with pkgs; [
    (bottles.override {
      removeWarningPopup = true;
    })
    dolphin-emu
    melonDS
    kh-melon-mix
    wwrando
    wwrando-ap
    ffmpeg-full
    gcfeeder
    gcviewer
    gcfeederd
    gimp3
    imhex
    inkscape
    jetbrains.idea
    jetbrains.rider
    (ghidra.withExtensions (_: [ghidra-extensions.gamecube-loader]))
    heroic
    keymapp
    krita
    libreoffice
    mangohud
    ntfs3g
    (wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
      ];
    })
    openmw
    (prismlauncher.override {
      jdks = [
        temurin-bin-8
        config.my.jdk
      ];
    })
    mcpelauncher-ui-qt
    protontricks
    scarab
    spotify
    sticky-notes
    transmission_4-gtk
    (discord-canary.override {withMoonlight = true;})
    vlc
    wineWowPackages.stableFull
    winetricks
    wgnord
    xivlauncher
    qemu # Workaround for libvirtd efi not working.
    virtiofsd # For virtio support in QEMU.
  ];
}
