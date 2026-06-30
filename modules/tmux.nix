{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    extraConfig = ''
      set -as terminal-features ",xterm-ghostty:RGB,xterm-256color:RGB"
    '';
  };
}
