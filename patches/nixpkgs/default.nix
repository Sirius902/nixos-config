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
    # TODO(Sirius902) Drop once nixpkgs' gradle update script stops binding nixpkgs.
    {
      file = ./gradle-drop-nixpkgs-bind.patch;
    }
    # Update nix-update to 1.17.0 https://github.com/NixOS/nixpkgs/pull/591736
    {
      commit = "d164824ab9f0413b0a3cbb69ad076c18480dae94";
    }
  ];
}
