final: prev:
prev.cosmic-applets.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-13";

  src = prevAttrs.src.override {
    tag = null;
    rev = "467716c1678b7ec33e0b836e5bda1970de0c452a";
    hash = "sha256-kgzGMni8neCz6cFtBYd26xvotq6ezBKJtTAHMTF/mEU=";
  };

  cargoHash = "sha256-mpwBsBlA53OCoG1xT+YQzKrzpCDnec7ImJfZEfBrndw=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };

  # FUTURE(Sirius902) Remove this if upstream removes the bluetooth spam patch (already applied here).
  patches = builtins.filter (p: p.name != "fix-bluetooth-dbus-spam.patch") (prevAttrs.patches or []);

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = final.nix-update-script {
        extraArgs = [
          "--version-regex"
          "epoch-(.*)"
        ];
      };
    };
})
