final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.193";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "f7513a30385ad9019c237226fd6ec46508b3062ebefca8aedbe397d111a818ff";
    "darwin-x64" = "cba5c3bdca8ab5f8e7590406702d418f6114d9b39f48f16876680e881abf1ee8";
    "linux-arm64" = "39454ce62e795eeb4871a81f6453cda96e926e2db9a4dd41d0ec1b60b0153448";
    "linux-x64" = "c9f04d929f18bd9a101f3897f27de4e1e0f15ebe8400d4aaf02983d73dd66b1d";
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
