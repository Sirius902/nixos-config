{pkgs, ...}: {
  programs.helix = {
    enable = true;
    defaultEditor = true;
    extraConfig = ''
      theme = "kanagawa"

      [editor]
      line-number = "relative"
      insert-final-newline = true
      trim-trailing-whitespace = true

      [editor.indent-guides]
      render = true
      # character = "┊"

      [keys.normal]
      Y = "yank_joined"
      # Stage/view diff hunks via lazygit; Helix has no builtin staging.
      # https://github.com/helix-editor/helix/wiki/Recipes
      C-g = [":write-all", ":insert-output lazygit >/dev/tty", ":redraw", ":reload-all"]

      [keys.select]
      Y = "yank_joined"

      # FUTURE(Sirius902) Enable sticky context once this is resolved.
      # https://github.com/helix-editor/helix/issues/396
    '';
    # FUTURE(Sirius902) Remove once this is fixed from taplo I guess.
    # https://github.com/helix-editor/helix/pull/9915#issuecomment-2214001123
    languages.language = [
      {
        name = "toml";
        roots = ["."];
      }
    ];
  };

  home.packages = [pkgs.lazygit];
}
