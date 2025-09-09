{
  sdl3,
  nix-update-script,
  ...
}:
sdl3.overrideAttrs (finalAttrs: prevAttrs: {
  pname = "${prevAttrs.pname}-git";
  version = "3.2.22-unstable-2025-09-09";
  src = prevAttrs.src.override {
    tag = null;
    rev = "b59d6d49c3314543e7f224716746946bbc89fb22";
    hash = "sha256-Xj80Kz4QxvMcV7FhECCLMQs7jFb4d3pben2fOqVPk7E=";
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = nix-update-script {
        extraArgs = [
          "--version=branch"
          "--version-regex"
          "release-(3\\..*)"
        ];
      };
    };

  meta = prevAttrs.meta // {changelog = null;};
})
