final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.203";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "57b5aec68a35f42036bd2f82836d91c2d2990c2d589fb3465e3ee87142af9a1e";
    "darwin-x64" = "1481cffd33d5d19219b53d832fb14e4c2c2def781fc4f1db6c5a4b2d1e596763";
    "linux-arm64" = "59bf43c7fc8c254a2d7a994f26d577a50f17876e4ed180cff6a1cef2f9ebe473";
    "linux-x64" = "85e4d203c5b43c67a778efd25dcc9ae1d239110c87726df5c6ac0774b576cc6c";
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
