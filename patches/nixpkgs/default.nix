{
  base = {
    owner = "NixOS";
    repo = "nixpkgs";
    ref = "nixos-unstable";
  };

  fork = "Sirius902/nixpkgs";
  branch = "nixos-config";

  patches = [
    # Add cosmic-ext-applet-clipboard-manager https://github.com/NixOS/nixpkgs/pull/496706
    {
      pr = 496706;
    }
    # Fix codex build with sys libs https://github.com/NixOS/nixpkgs/pull/584667
    {
      commit = "16b463698a5b9f20881b6c5f1150ce37e2456db9";
    }
  ];
}
