final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.170";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "e903646d8b7a31882a80ecd27569a27d8ac57b3708745f349709632c84117fdf";
    "darwin-x64" = "914f23a70bbed5d9ae567e3e04b86206ed9971b371bc9baca3f79c8885bfddb4";
    "linux-arm64" = "1bb9d032440a75532f7dd4cafbc687f220aaf16c63eba17e192dfbec2f04bd25";
    "linux-x64" = "849e007277a0442ab27570d3e3d6d43787507946590e8dd1947e5a39b7081f9e";
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
