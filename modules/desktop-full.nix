{pkgs, ...}: {
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
          })
          .fd
        ];
      };
    };
    # TODO: Use hooks.qemu instead of symlinking in libvirtd service.
    #hooks.qemu = { };
  };
  programs.virt-manager.enable = true;

  # Symlink /persist/etc/libvirt to /etc/libvirt
  environment.etc."libvirt".source = "/persist/etc/libvirt";

  # Symlink /persist/var/lib/libvirt to /var/lib/libvirt
  systemd.tmpfiles.rules = [
    "L /var/lib/libvirt - - - - /persist/var/lib/libvirt"
  ];

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

  users.users.chris.extraGroups = ["libvirtd" "openrazer"];

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
    coolercontrol = {
      enable = true;
      nvidiaSupport = true;
    };
  };

  services.udev.extraRules = ''
    # GameCube Controller Adapter
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", TAG+="uaccess"

    # Nintendo Switch
    SUBSYSTEM=="usb", ATTR{idVendor}=="0955", MODE="0664", TAG+="uaccess"
  '';

  # For wgnord
  services.resolved.enable = true;

  environment.systemPackages = with pkgs; [
    bottles
    dolphin-emu-beta
    ffmpeg-full
    gimp
    godot_4
    inkscape
    jetbrains.idea-community
    jetbrains.rider
    heroic
    keymapp
    krita
    libreoffice-qt
    lunar-client
    (wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
        obs-vkcapture
      ];
    })
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
    (wineWowPackages.unstable.override {
      waylandSupport = true;
    })
    winetricks
    wgnord
    xivlauncher
    qemu # Workaround for libvirtd efi not working.
    virtiofsd # For virtio support in QEMU.
  ];
}
