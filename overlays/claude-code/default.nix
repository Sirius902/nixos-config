final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.183";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "6218efccd06194ea0bc381121bf03040a027a04d991eaed886da02a00449ad0f";
    "darwin-x64" = "c70248f96b5831ff86ac169ab53c87ec5480f91ae386783da11004875c2ad1b7";
    "linux-arm64" = "260a6e43fe9c6fd8800317581982ff50e4f4401d02ef625faa4df723bb9710b3";
    "linux-x64" = "df3b409c5b25299df52c5ee81f64811dbdcb2e18c1beefe7f733c326f0a8cdce";
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
