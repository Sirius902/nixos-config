final: prev: let
  sources = final.lib.importJSON ./sources.json;
in {
  graalvmPackages = prev.graalvmPackages.overrideScope (_: gprev: {
    graalvm-oracle = gprev.graalvm-oracle.overrideAttrs (finalAttrs: prevAttrs: {
      inherit (sources) version;
      src = final.fetchurl sources.platforms.${final.stdenv.hostPlatform.system};

      passthru =
        (prevAttrs.passthru or {})
        // {
          # TODO(Sirius902) Drop once buildGraalvm's `home` follows overrideAttrs
          # rather than naming the derivation it built.
          home = finalAttrs.finalPackage;
          updateScript = ./update.sh;
        };

      meta = prevAttrs.meta // {platforms = builtins.attrNames sources.platforms;};
    });
  });

  # The flake's update app and `packages` only see top-level derivations.
  graalvm-oracle = final.graalvmPackages.graalvm-oracle;
}
