final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.231";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "ba790279cab6ef77b713864d4bf5f764fcea87d3a3eb7591a41f741e45212b5c";
    "darwin-x64" = "7c7c6179f55c985409af4c31603d19b9b64af4759d016f86b99bfbdb29042a90";
    "linux-arm64" = "4ee7c484b11dece6521aa2173a19ea913428c1c78599186d62559d2d2aef4e32";
    "linux-x64" = "47a01daebf794f6c86c13d1875ad6e5be0627029ad8600731161f24018ecde5b";
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
