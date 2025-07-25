{pkgs, ...}: {
  imports = [
    ./default.nix
    ./rnnoise.nix
  ];

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

  fileSystems."/var/lib/libvirt" = {
    device = "/persist/var/lib/libvirt";
    fsType = "none";
    options = ["bind" "noauto"];
  };

  systemd.services.libvirtd = {
    preStart = ''
      mkdir -p /var/lib/libvirt/hooks/
      ln -sf /persist/qemu-hooks/qemu /var/lib/libvirt/hooks/qemu
      ln -sf /persist/qemu-hooks/kvm.conf /var/lib/libvirt/hooks/kvm.conf

      mkdir -p /var/lib/libvirt/hooks/qemu.d/win11-vfio/prepare/begin/
      mkdir -p /var/lib/libvirt/hooks/qemu.d/win11-vfio/release/end/
      ln -sf /persist/qemu-hooks/vfio/start.sh /var/lib/libvirt/hooks/qemu.d/win11-vfio/prepare/begin/start.sh
      ln -sf /persist/qemu-hooks/vfio/stop.sh /var/lib/libvirt/hooks/qemu.d/win11-vfio/release/end/stop.sh

      mkdir -p /var/lib/libvirt/hooks/qemu.d/win10-vfio/prepare/begin/
      mkdir -p /var/lib/libvirt/hooks/qemu.d/win10-vfio/release/end/
      ln -sf /persist/qemu-hooks/vfio/start.sh /var/lib/libvirt/hooks/qemu.d/win10-vfio/prepare/begin/start.sh
      ln -sf /persist/qemu-hooks/vfio/stop.sh /var/lib/libvirt/hooks/qemu.d/win10-vfio/release/end/stop.sh
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

  environment.systemPackages = with pkgs; [
    (bottles.override {
      removeWarningPopup = true;
    })
    dolphin-emu-beta
    ffmpeg-full
    gcfeeder
    gcviewer
    gcfeederd
    gimp3
    godot_4
    imhex
    inkscape
    jetbrains.idea-community
    idea-community-mc-dev
    jetbrains.rider
    (ghidra.withExtensions (_: [ghidra-extensions.gamecube-loader]))
    heroic
    keymapp
    krita
    libreoffice-qt
    lunar-client
    ntfs3g
    (wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
      ];
    })
    openmw
    openrazer-daemon
    polychromatic
    (prismlauncher.override {
      jdks = [
        graalvm-oracle
        temurin-bin-8
      ];
    })
    protontricks
    scarab
    spotify
    sticky-notes
    transmission_4-qt
    (discord-canary.override {withMoonlight = true;})
    vlc
    wineWowPackages.stagingFull
    winetricks
    wgnord
    xivlauncher
    qemu # Workaround for libvirtd efi not working.
    virtiofsd # For virtio support in QEMU.
  ];
}
