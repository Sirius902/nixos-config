final: prev:
prev.lib.mapAttrs (name: overlay:
    (overlay final prev).overrideAttrs (finalAttrs: prevAttrs: {
      env =
        (prevAttrs.env or {})
        // {
          VERGEN_GIT_COMMIT_DATE = let
            m = builtins.match ".*-unstable-(.*)" finalAttrs.version;
          in
            if m != null
            then builtins.head m
            else "";
          VERGEN_GIT_SHA = finalAttrs.src.rev;
        };
    })) (import ./overlays.nix)
