final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.204";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "1677b67595b6251156d62600dc85d4070ec385b72dd0b07e73742a56030952c3";
    "darwin-x64" = "9ccea5f19ec0462f3b983ff3400a97adaf16a83c3dc36a69b916805f2bc8c829";
    "linux-arm64" = "c37256a8c3998b8675e8385f1ae4677d69bdff1e717c389296eec70e02e317ef";
    "linux-x64" = "c8ee1ea69154533c691a68f46abb645196fe7339d26e6fc204cc7f08220139d3";
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
