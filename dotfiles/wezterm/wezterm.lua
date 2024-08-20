-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'Gruvbox Dark (Gogh)'

-- config.font_size = 14.0

-- Disable font ligatures
config.harfbuzz_features = {'calt=0', 'clig=0', 'liga=0'}

config.hide_mouse_cursor_when_typing = false

-- TODO: Uncomment once blur is added for background
--config.window_background_opacity = 0.8

-- TODO: Workaround to fix font rendering on NixOS unstable.
config.front_end = 'WebGpu'

-- Use GNOME cursor style
local success, stdout, _ = wezterm.run_child_process({"gsettings", "get", "org.gnome.desktop.interface", "cursor-theme"})
if success then
  config.xcursor_theme = stdout:gsub("'(.+)'\n", "%1")
end

local success, stdout, _ = wezterm.run_child_process({"gsettings", "get", "org.gnome.desktop.interface", "cursor-size"})
if success then
  config.xcursor_size = tonumber(stdout)
end

-- and finally, return the configuration to wezterm
return config
