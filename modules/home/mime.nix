{
  config,
  lib,
  pkgs,
  ...
}: let
  browser = "firefox.desktop";
  fileManager = "com.system76.CosmicFiles.desktop";
  imageViewer = "org.gnome.Loupe.desktop";
  docViewer = "org.gnome.Papers.desktop";
  mediaPlayer = "vlc.desktop";
  editor = "helix-ghostty.desktop";
  terminal = "ghostty-cwd.desktop";
  torrent = "transmission-gtk.desktop";

  imageTypes = [
    "image/png"
    "image/jpeg"
    "image/gif"
    "image/webp"
    "image/bmp"
    "image/tiff"
    "image/svg+xml"
    "image/avif"
    "image/heic"
    "image/jxl"
    "image/x-icon"
    "image/vnd.microsoft.icon"
    "image/x-tga"
    "image/qoi"
  ];

  videoTypes = [
    "video/mp4"
    "video/x-matroska"
    "video/webm"
    "video/quicktime"
    "video/x-msvideo"
    "video/mpeg"
    "video/x-flv"
    "video/3gpp"
    "video/ogg"
    "video/x-ms-wmv"
    "video/mp2t"
    "video/x-m4v"
  ];

  audioTypes = [
    "audio/mpeg"
    "audio/flac"
    "audio/x-flac"
    "audio/mp4"
    "audio/x-m4a"
    "audio/aac"
    "audio/ogg"
    "audio/x-vorbis+ogg"
    "audio/opus"
    "audio/wav"
    "audio/x-wav"
    "audio/webm"
    "audio/x-matroska"
  ];

  textTypes = [
    "text/plain"
    "text/markdown"
    "text/x-markdown"
    "application/json"
    "text/xml"
    "application/xml"
    "text/css"
    "application/javascript"
    "text/x-python"
    "application/x-shellscript"
    "text/x-shellscript"
    "text/x-makefile"
    "text/x-c"
    "text/x-csrc"
    "text/x-chdr"
    "text/x-c++"
    "text/x-c++src"
    "text/x-c++hdr"
    "text/x-java"
    "text/x-tex"
    "application/toml"
    "application/x-yaml"
  ];
in {
  home.packages = with pkgs; [
    loupe
    papers
  ];

  xdg.desktopEntries.helix-ghostty = {
    name = "Helix (Ghostty)";
    genericName = "Text Editor";
    comment = "Edit text files with Helix in Ghostty";
    exec = "ghostty -e hx %F";
    icon = "helix";
    terminal = false;
    type = "Application";
    categories = ["Utility" "TextEditor"];
    mimeType = textTypes;
    noDisplay = true;
    startupNotify = false;
  };

  xdg.desktopEntries.ghostty-cwd = {
    name = "Ghostty";
    genericName = "Terminal";
    exec = "ghostty +new-window";
    icon = "com.mitchellh.ghostty";
    terminal = false;
    type = "Application";
    categories = ["System" "TerminalEmulator"];
    noDisplay = true;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      {
        "text/html" = browser;
        "application/xhtml+xml" = browser;
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;

        "inode/directory" = fileManager;
        "inode/mount-point" = fileManager;

        "application/pdf" = docViewer;
        "image/vnd.djvu" = docViewer;
        "application/x-cbz" = docViewer;
        "application/x-cbr" = docViewer;

        "x-scheme-handler/terminal" = terminal;
        "application/x-terminal-emulator" = terminal;

        "x-scheme-handler/magnet" = torrent;
        "application/x-bittorrent" = torrent;
      }
      // lib.genAttrs imageTypes (_: imageViewer)
      // lib.genAttrs videoTypes (_: mediaPlayer)
      // lib.genAttrs audioTypes (_: mediaPlayer)
      // lib.genAttrs textTypes (_: editor);
  };

  xdg.configFile."niri-mimeapps.list".source = config.xdg.configFile."mimeapps.list".source;
}
