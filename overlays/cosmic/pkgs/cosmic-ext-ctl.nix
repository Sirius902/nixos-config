final: prev:
prev.cosmic-ext-ctl.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.5.0-unstable-2025-05-02";

  src = prevAttrs.src.override {
    tag = null;
    rev = "08b4e26ceddcba8d3df8df29ae865055a5bc3a04";
    hash = "sha256-URqNhkC1XrXYxr14K6sT3TLso38eWLMA+WplBdj52Vg=";
  };

  cargoHash = "sha256-OL1LqOAyIFFCGIp3ySdvEXJ1ECp9DgC/8mfAPo/E7k4=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };

  passthru.updateScript = final.nix-update-script {};
})
