{pkgs, ...}: let
  caffeineToggle = pkgs.writeShellScript "caffeine-toggle" ''
    if pgrep -f 'systemd-inhibit.*caffeine' >/dev/null 2>&1; then
      pkill -f 'systemd-inhibit.*caffeine'
    else
      systemd-inhibit --what=idle --why=caffeine --who=waybar sleep infinity &
    fi
    pkill -RTMIN+8 waybar
  '';

  caffeineStatus = pkgs.writeShellScript "caffeine-status" ''
    if pgrep -f 'systemd-inhibit.*caffeine' >/dev/null 2>&1; then
      echo '{"text": "☕", "tooltip": "Caffeine on", "class": "activated"}'
    else
      echo '{"text": "💤", "tooltip": "Caffeine off", "class": "deactivated"}'
    fi
  '';

  powerMenu = pkgs.writeShellScript "power-menu" ''
    choice=$(printf "Lock\nSuspend\nReboot\nShutdown\nLogout" | fuzzel --dmenu --prompt "Power: ")
    case "$choice" in
      Lock) swaylock -f ;;
      Suspend) swaylock -f && systemctl suspend ;;
      Reboot) systemctl reboot ;;
      Shutdown) systemctl poweroff ;;
      Logout) niri msg action quit ;;
    esac
  '';
in {
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  # GTK3 default (500ms) makes waybar tooltips feel sluggish.
  gtk.gtk3.extraConfig."gtk-tooltip-timeout" = 100;

  xdg.configFile."systemd/user/xdg-desktop-portal-gtk.service.d/dark-theme.conf".text = ''
    [Service]
    Environment=GTK_THEME=Adwaita:dark
  '';
  xdg.configFile."systemd/user/xdg-desktop-portal-gnome.service.d/dark-theme.conf".text = ''
    [Service]
    Environment=GTK_THEME=Adwaita:dark
  '';

  xdg.configFile."autostart/nm-applet.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';

  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            repeat-delay 400
            repeat-rate 25
            xkb {
                layout "us"
            }
        }
        touchpad {
            tap
            natural-scroll
        }
    }

    output "DP-1" {
        mode "2560x1440@165.080"
        variable-refresh-rate on-demand=true
    }

    output "DP-2" {
        mode "2560x1440@165.080"
        variable-refresh-rate on-demand=true
    }

    layout {
        gaps 8
        center-focused-column "on-overflow"
        default-column-width { proportion 0.5; }

        preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
        }

        focus-ring {
            width 3
            active-color "#7263df"
            inactive-color "#4c4c4c"
        }
    }

    // Match COSMIC window corner rounding
    window-rule {
        geometry-corner-radius 8 8 8 8
        clip-to-geometry true
    }

    prefer-no-csd

    screenshot-path "~/Pictures/Screenshots/Screenshot_%Y-%m-%d_%H-%M-%S.png"

    // Startup
    spawn-at-startup "xwayland-satellite"
    spawn-at-startup "swaybg" "-m" "fill" "-i" "/home/chris/Pictures/Screenshot_2025-05-08_23-50-08.png"
    spawn-at-startup "env" "GTK_THEME=Adwaita:dark" "waybar"
    spawn-at-startup "mako"
    spawn-at-startup "sunsetr"
    spawn-at-startup "swayidle" "-w" "timeout" "300" "swaylock -f" "timeout" "300" "niri msg action power-off-monitors" "resume" "niri msg action power-on-monitors"
    spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"

    hotkey-overlay {
        skip-at-startup
    }

    binds {
        // Apps
        Mod+Return { spawn "ghostty"; }
        Mod+D { spawn "fuzzel"; }
        Mod+E { spawn "cosmic-files"; }
        Mod+Q { close-window; }
        Mod+Shift+Slash { show-hotkey-overlay; }
        Mod+W { toggle-overview; }
        Mod+Escape { spawn "swaylock" "-f"; }

        // Focus
        Mod+H     { focus-column-left; }
        Mod+L     { focus-column-right; }
        Mod+J     { focus-window-down; }
        Mod+K     { focus-window-up; }
        Mod+Left      { focus-column-left; }
        Mod+Right     { focus-column-right; }
        Mod+Down      { focus-window-down; }
        Mod+Up        { focus-window-up; }

        // Move
        Mod+Shift+H     { move-column-left; }
        Mod+Shift+L     { move-column-right; }
        Mod+Shift+J     { move-window-down; }
        Mod+Shift+K     { move-window-up; }
        Mod+Shift+Left      { move-column-left; }
        Mod+Shift+Right     { move-column-right; }
        Mod+Shift+Down      { move-window-down; }
        Mod+Shift+Up        { move-window-up; }

        // Column / window manipulation
        Mod+R       { switch-preset-column-width; }
        Mod+F       { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        Mod+Comma   { consume-window-into-column; }
        Mod+Period  { expel-window-from-column; }
        Mod+C       { center-column; }

        // Workspaces
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+Shift+1 { move-window-to-workspace 1; }
        Mod+Shift+2 { move-window-to-workspace 2; }
        Mod+Shift+3 { move-window-to-workspace 3; }
        Mod+Shift+4 { move-window-to-workspace 4; }
        Mod+Shift+5 { move-window-to-workspace 5; }
        Mod+Shift+6 { move-window-to-workspace 6; }
        Mod+Shift+7 { move-window-to-workspace 7; }
        Mod+Shift+8 { move-window-to-workspace 8; }
        Mod+Shift+9 { move-window-to-workspace 9; }
        Mod+Page_Down      { focus-workspace-down; }
        Mod+Page_Up        { focus-workspace-up; }
        Mod+Ctrl+Page_Down { move-workspace-down; }
        Mod+Ctrl+Page_Up   { move-workspace-up; }

        // Monitors
        Mod+Ctrl+Left  { focus-monitor-left; }
        Mod+Ctrl+Right { focus-monitor-right; }
        Mod+Ctrl+Shift+Left  { move-window-to-monitor-left; }
        Mod+Ctrl+Shift+Right { move-window-to-monitor-right; }
        Mod+Home { move-workspace-to-monitor-left; }
        Mod+End  { move-workspace-to-monitor-right; }

        // Screenshots
        Print           { screenshot; }
        Mod+Print       { screenshot-screen; }
        Mod+Shift+Print { screenshot-window; }

        // Audio / Media
        XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05+"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.05-"; }
        XF86AudioMute        allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86AudioPlay        allow-when-locked=true { spawn "playerctl" "play-pause"; }
        XF86AudioNext        allow-when-locked=true { spawn "playerctl" "next"; }
        XF86AudioPrev        allow-when-locked=true { spawn "playerctl" "previous"; }

        // Night shift toggle
        Mod+N { spawn "sh" "-c" "if sunsetr status | grep -q 'State: static'; then sunsetr set transition_mode=finish_by; else sunsetr set transition_mode=static; fi"; }

        // Session
        Mod+Shift+Escape { spawn "${powerMenu}"; }
        Mod+Shift+P { power-off-monitors; }
    }
  '';

  xdg.configFile."swaylock/config".text = ''
    image=/home/chris/Pictures/Screenshot_2025-05-08_23-50-08.png
    scaling=fill
    effect-blur=20x6
    effect-vignette=0.3:0.8

    clock
    timestr=%I:%M %p
    datestr=%A, %B %e

    font=JetBrainsMono Nerd Font
    font-size=28
    text-color=e0e0e0

    indicator
    indicator-radius=150
    indicator-thickness=6

    color=1b1b1b
    inside-color=1b1b1b00
    ring-color=7263df40
    key-hl-color=7263df
    line-color=00000000
    separator-color=00000000

    inside-ver-color=1b1b1b00
    ring-ver-color=7263df
    text-ver-color=e0e0e0
    inside-wrong-color=1b1b1b00
    ring-wrong-color=cc6666
    text-wrong-color=cc6666
    bs-hl-color=cc6666

    inside-clear-color=1b1b1b00
    ring-clear-color=e6c84d
    text-clear-color=e0e0e0
  '';

  xdg.configFile."waybar/config".text = builtins.toJSON {
    layer = "top";
    position = "top";
    height = 30;
    modules-left = ["niri/workspaces" "niri/window"];
    modules-center = ["clock"];
    modules-right = ["custom/caffeine" "cpu" "memory" "tray" "wireplumber" "network"];
    "niri/workspaces" = {
      format = "{icon}";
      format-icons = {
        active = "";
        default = "";
      };
    };
    "niri/window" = {
      max-length = 50;
    };
    clock = {
      format = "{:%a %b %d  %I:%M %p}";
      tooltip-format = "<tt>{calendar}</tt>";
    };
    "custom/caffeine" = {
      exec = "${caffeineStatus}";
      return-type = "json";
      interval = "once";
      signal = 8;
      on-click = "${caffeineToggle}";
    };
    cpu = {
      format = "CPU {usage}%";
      interval = 5;
      states = {
        warning = 50;
        critical = 80;
      };
    };
    memory = {
      format = "RAM {percentage}%";
      interval = 5;
      states = {
        warning = 50;
        critical = 80;
      };
    };
    wireplumber = {
      format = "{icon} {volume}%";
      format-muted = " muted";
      format-icons = ["" "" ""];
      on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      on-click-right = "cosmic-settings sound";
    };
    network = {
      format-wifi = " {essid}";
      format-ethernet = " {ifname}";
      format-disconnected = " disconnected";
      tooltip-format = "{ipaddr}";
    };
    tray = {
      spacing = 8;
    };
  };

  xdg.configFile."waybar/style.css".text = ''
    * {
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 13px;
    }

    window#waybar {
        background-color: rgba(27, 27, 27, 0.9);
        color: #e0e0e0;
    }

    #workspaces button {
        padding: 0 6px;
        color: #888;
        border: none;
        border-radius: 0;
    }

    #workspaces button.active {
        color: #7263df;
    }

    #clock, #wireplumber, #network, #tray, #cpu, #memory, #idle-inhibitor {
        padding: 0 10px;
    }

    #custom-caffeine.activated {
        color: #7263df;
    }

    #cpu.warning, #memory.warning {
        color: #e6c84d;
    }

    #cpu.critical, #memory.critical {
        color: #cc6666;
    }

    #window {
        padding: 0 10px;
        color: #aaa;
    }
  '';

  xdg.configFile."fuzzel/fuzzel.ini".text = ''
    [main]
    font=JetBrainsMono Nerd Font:size=12
    terminal=ghostty -e
    layer=overlay
    show-actions=yes
    match-mode=fzf
    icon-theme=Cosmic
    placeholder=Search apps...
    selection-radius=8

    [colors]
    background=1b1b1bee
    text=e0e0e0ff
    match=7263dfff
    selection=7263df40
    selection-text=e0e0e0ff
    border=7263dfff
    prompt=7263dfff

    [border]
    radius=8
    width=2
  '';

  xdg.configFile."mako/config".text = ''
    font=JetBrainsMono Nerd Font 11
    background-color=#1b1b1bee
    text-color=#e0e0e0
    border-color=#7263df
    border-radius=8
    border-size=2
    padding=12
    max-visible=5
    max-lines=10
    default-timeout=5000
  '';

  xdg.configFile."sunsetr/sunsetr.toml".text = ''
    transition_mode = "finish_by"
    sunset = "20:00:00"
    sunrise = "07:00:00"
    transition_duration = 45
    night_temp = 3400
    day_temp = 6500
    night_gamma = 100
    day_gamma = 100
    static_temp = 3400
    static_gamma = 100
  '';
}
