final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.226";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "013a1cf17df5ff1dcc189d5d6fd3fdd5f097ddc3cd41aa9992e99805574febbe";
    "darwin-x64" = "773b095876f13ddb8336bfae202a57c62e358b1882746f1d55e3680601a32c59";
    "linux-arm64" = "feb715ee066d02a400c9d83941592f11c8e8fa6628c1e3c14262bc529f950498";
    "linux-x64" = "4e9bec1177ce9690e8bd988b710ac24105e70da428dd094c5adcbbe786a55555";
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
