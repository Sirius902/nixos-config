{pkgs, ...}: {
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

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

  # FUTURE(Sirius902) noctalia's config watcher misses home-manager's atomic
  # symlink swaps; drop this nudge once it watches the directory instead of
  # the file inode.
  xdg.configFile."noctalia/config.toml".onChange = "${pkgs.noctalia}/bin/noctalia msg config-reload || true";

  xdg.configFile."noctalia/config.toml".text = ''
    [shell]
    polkit_agent = true
    time_format = "{:%I:%M %p}"

    [[shell.session.actions]]
    action = "lock"
    shortcut = "1"

    [[shell.session.actions]]
    action = "command"
    command = "noctalia msg session lock && niri msg action power-off-monitors"
    label = "Lock & Display Off"
    shortcut = "2"

    [[shell.session.actions]]
    action = "lock_and_suspend"
    shortcut = "3"

    [[shell.session.actions]]
    action = "logout"
    shortcut = "4"

    [[shell.session.actions]]
    action = "reboot"
    shortcut = "5"

    [[shell.session.actions]]
    action = "shutdown"
    shortcut = "6"
    variant = "destructive"

    [widget.clock]
    format = "{:%-I:%M %p}"

    [widget.cpu]
    type = "sysmon"
    stat = "cpu_usage"

    [widget.ram]
    type = "sysmon"
    stat = "ram_pct"

    [bar.default]
    end = [
        "caffeine",
        "cpu",
        "ram",
        "media",
        "tray",
        "notifications",
        "clipboard",
        "network",
        "bluetooth",
        "volume",
        "brightness",
        "battery",
        "control-center",
        "session"
    ]

    [idle.behavior.lock]
    enabled = true
    timeout = 300.0

    [idle.behavior.screen-off]
    enabled = true
    timeout = 300.0

    [idle.behavior.lock-and-suspend]
    enabled = true
    timeout = 900.0

    [nightlight]
    enabled = true
    temperature_day = 6500
    temperature_night = 3400

    [location]
    custom_schedule = true
    sunset = "20:00"
    sunrise = "07:00"

    [calendar]
    event_time_format = "%I:%M %p"

    [theme]
    source = "builtin"
    builtin = "Kanagawa"

    [wallpaper]
    directory = "~/Pictures/Backgrounds"
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

    window-rule {
        geometry-corner-radius 8 8 8 8
        clip-to-geometry true
    }

    window-rule {
        match app-id="dev.noctalia.Noctalia"
        open-floating true
    }

    prefer-no-csd

    screenshot-path "~/Pictures/Screenshots/Screenshot_%Y-%m-%d_%H-%M-%S.png"

    // Startup
    spawn-at-startup "xwayland-satellite"
    spawn-at-startup "noctalia"

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
        Mod+O { toggle-overview; }
        Mod+Escape { spawn "noctalia" "msg" "session" "lock"; }

        // Noctalia
        Mod+Shift+Space { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
        Mod+A { spawn "noctalia" "msg" "panel-toggle" "control-center"; }
        Mod+Shift+A { spawn "noctalia" "msg" "settings-toggle"; }

        // Focus
        Mod+H     { focus-column-left; }
        Mod+L     { focus-column-right; }
        Mod+J     { focus-window-down; }
        Mod+K     { focus-window-up; }

        // Move
        Mod+Shift+H     { move-column-left; }
        Mod+Shift+L     { move-column-right; }
        Mod+Shift+J     { move-window-down; }
        Mod+Shift+K     { move-window-up; }

        // Column / window manipulation
        Mod+R       { switch-preset-column-width; }
        Mod+F       { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        Mod+Ctrl+F  { expand-column-to-available-width; }
        Mod+Comma   { consume-window-into-column; }
        Mod+Period  { expel-window-from-column; }
        Mod+C       { center-column; }

        // Resize
        Mod+Ctrl+H { set-column-width "-5%"; }
        Mod+Ctrl+L { set-column-width "+5%"; }
        Mod+Ctrl+K { set-window-height "-5%"; }
        Mod+Ctrl+J { set-window-height "+5%"; }

        // Floating / tabbed
        Mod+V       { toggle-window-floating; }
        Mod+Shift+V { switch-focus-between-floating-and-tiling; }
        Mod+T       { toggle-column-tabbed-display; }

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
        // Monitors (arrow left/right)
        Mod+Left       { focus-monitor-left; }
        Mod+Right      { focus-monitor-right; }
        Mod+Shift+Left  { move-window-to-monitor-left; }
        Mod+Shift+Right { move-window-to-monitor-right; }
        Mod+Home { move-workspace-to-monitor-left; }
        Mod+End  { move-workspace-to-monitor-right; }

        // Workspace cycling (arrow up/down)
        Mod+Up         { focus-workspace-up; }
        Mod+Down       { focus-workspace-down; }
        Mod+Shift+Up   { move-workspace-up; }
        Mod+Shift+Down { move-workspace-down; }

        // Screenshots
        Print           { screenshot; }
        Mod+Print       { screenshot-window; }
        Mod+Shift+Print { screenshot-screen; }
        Mod+S           { screenshot; }
        Mod+Shift+S     { screenshot-window; }
        Mod+Ctrl+S      { screenshot-screen; }

        // Audio / Media
        XF86AudioRaiseVolume allow-when-locked=true { spawn "noctalia" "msg" "volume-up"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "noctalia" "msg" "volume-down"; }
        XF86AudioMute        allow-when-locked=true { spawn "noctalia" "msg" "volume-mute"; }
        XF86AudioPlay        allow-when-locked=true { spawn "noctalia" "msg" "media" "toggle"; }
        XF86AudioNext        allow-when-locked=true { spawn "noctalia" "msg" "media" "next"; }
        XF86AudioPrev        allow-when-locked=true { spawn "noctalia" "msg" "media" "previous"; }

        // Night shift toggle
        Mod+N { spawn "noctalia" "msg" "nightlight-toggle"; }

        // Notifications
        Mod+X       { spawn "noctalia" "msg" "notification-clear-active"; }
        Mod+Shift+X { spawn "noctalia" "msg" "notification-dnd-toggle"; }

        // Session
        Mod+Shift+Escape { spawn "noctalia" "msg" "panel-toggle" "session"; }
        Mod+Shift+P { power-off-monitors; }
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
    selection-match=7263dfff
    border=7263dfff
    prompt=7263dfff

    [border]
    radius=8
    width=2
  '';
}
