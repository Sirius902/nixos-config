final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.143";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "2701c6cfd68483f8faf0316a1ba6481a1455a90645ada179f0c48d8c36d722ef";
    "darwin-x64" = "bc8ff4ce02b765a033808fb596f9522306cbe5c50d21344ed8752c08966f362c";
    "linux-arm64" = "32e8edc4a5c3c41d18607c75d1b8e7bec643330c03e266be46ac3b41a446c4eb";
    "linux-x64" = "f75fdc3ff9d9cd494b86192f9e349b5c5c6d3970ed4d5cd5c7b330c5a2b1dcc4";
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
