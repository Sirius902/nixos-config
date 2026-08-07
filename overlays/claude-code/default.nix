final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.224";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "391df9d2ab04e4cf32199335720ac7715a582e91eaecfd4d2198a16f57ea59b3";
    "darwin-x64" = "7ae17a768a7270c7bd6c5484587c3c650dff425b4beeeb03addc1f2a4a7d702a";
    "linux-arm64" = "3e50836e227868746273653e0f8115cf5fc9cb34a081847c6040c81d80812c33";
    "linux-x64" = "a2b5add7dc4bcd8eaa029f4e8bdac4df7769b4073698db7989d206baf9419c2d";
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
