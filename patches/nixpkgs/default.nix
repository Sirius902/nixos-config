{
  base = {
    owner = "NixOS";
    repo = "nixpkgs";
    ref = "nixos-unstable";
  };

  fork = "Sirius902/nixpkgs";
  branch = "nixos-config";

  patches = [
    # TODO(Sirius902) Drop once nixpkgs' discord registers its bundled modules
    # on bootstraps without the legacy module updater.
    {
      file = ./discord-register-bundled-modules.patch;
    }
  ];
}
