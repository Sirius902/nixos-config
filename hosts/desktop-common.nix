{ config, inputs, pkgs, ... }:

{
  imports = [ ];

  environment.systemPackages = with pkgs; [
    jetbrains-mono
    nautilus-python # Required for Open in WezTerm.
    qdirstat
    wl-clipboard
    pure-prompt
    vscodium
  ];
}
