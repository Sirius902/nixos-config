{
  base = {
    owner = "NixOS";
    repo = "nixpkgs";
    ref = "nixos-unstable";
  };

  fork = "Sirius902/nixpkgs";
  branch = "nixos-config";

  patches = [
    # TODO(Sirius902) shadps4 needs zenity for errors. Make PR?
    {
      branch = "shadps4-zenity";
      against = "master";
      from = "Sirius902/nixpkgs";
    }
    # Add cosmic-ext-applet-clipboard-manager https://github.com/NixOS/nixpkgs/pull/496706
    {
      pr = 496706;
    }
    # TODO(Sirius902) poptracker wraps kdialog into PATH on darwin. Make PR?
    {
      file = ./poptracker-linux-dialog-helper.patch;
    }
  ];
}
