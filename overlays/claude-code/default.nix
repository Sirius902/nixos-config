final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.156";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "9c1e8601031f5cbb3101e49dda22bf8ba31183692c705e267a6923585fa2ba09";
    "darwin-x64" = "ccd608c694677324e24dec7d1253b51f887a7be838cdb75b22d5362c97351107";
    "linux-arm64" = "7ed95d0a93aeb40e2b98e234b760d9295b7044ef678c62db8d1f5e14bfd57878";
    "linux-x64" = "6d83cd2264450c5e54fc988be1032c288cf418ee604294acfb8fc4ac28f5f7a3";
  };
in {
  claude-code = prev.claude-code.overrideAttrs (prevAttrs: {
    inherit version;
    src = final.fetchurl {
      url = "${baseUrl}/${version}/${platformKey}/claude";
      sha256 = checksums.${platformKey};
    };

    passthru =
      (prevAttrs.passthru or {})
      // {
        updateScript = ./update.sh;
      };
  });
}
