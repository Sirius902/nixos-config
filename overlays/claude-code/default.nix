final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.154";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "bc9881b107d7be1743c64c8b72dd66798f5d0947dbc48ed0d77964c473661fd4";
    "darwin-x64" = "1608d93261879201dcf77dd32dc173efbeea715187d3542fd05afcf7d5b5ec4d";
    "linux-arm64" = "9f732de278f7adc61d29fd5b055ddaf1bae3bb26d75fe6e06a125602565777a8";
    "linux-x64" = "67f6cab7e6c124010f62ac18f8078bc09e0db6a5b9e8ae874e9e73033c451793";
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
