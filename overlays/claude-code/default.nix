final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.221";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "7a181f36ed0fc4fbac6cee4ecf2b615eff93d8b434221fff5d7c878dc5ebf380";
    "darwin-x64" = "f408b9f7e46439f6e34a3687ff67433fc6bc189f40220ce4f0a1e829e58f0a52";
    "linux-arm64" = "d3c59d6bcc4adcf4cd85abca3bc13fa1131a34cb32f982bdf030d83a3b11e700";
    "linux-x64" = "60db8e88d42c24b5199c92cfd56ec88370c510c3789c6f364af748354f087ada";
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
