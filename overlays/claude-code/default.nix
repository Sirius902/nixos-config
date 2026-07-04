final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.201";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "a0852d76afc47b30f5cb0b7625ec9a7714cb189f2eeef6c28c77e2be954fb7fd";
    "darwin-x64" = "1889287a92d25356ae8bd8d8e67b11456015516ee8ba4277a0c7074786c49bb6";
    "linux-arm64" = "86b2eab34d382c7b428fc2e9f4c97f04e46805e950582472a13eb7d48de60516";
    "linux-x64" = "a34809a6839fdefff21b9347d7fb5b6b58e6a9cc208a5e62853f29c83eb107a3";
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
