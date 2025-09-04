# TODO(Sirius902) Overlay new cosmic-comp until https://github.com/pop-os/cosmic-comp/pull/1481 makes it to nixos-unstable.
final: prev:
prev.cosmic-comp.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-04";

  src = prevAttrs.src.override {
    tag = null;
    rev = "c9e64acad2860e1068cf11468da00acc7ee2f86d";
    hash = "sha256-4DDdqWGmUFctMib2FNkaYc9m4ivPdBWd71Mc9XHZI+c=";
  };

  cargoHash = "sha256-wGq7Cdq56Hnzww+IVXCtZet4Zojj8VUmmsjsg53XHe8=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };

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
