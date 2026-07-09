{
  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g default-terminal "tmux-256color"
      set -as terminal-features ",xterm-ghostty:RGB,xterm-256color:RGB"
    '';
  };
}
