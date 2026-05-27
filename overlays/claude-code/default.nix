final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.152";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "43cb9361f7bc48c39214d5f125003b8de0ebde5cd6a1173e6b74fcdd10966d46";
    "darwin-x64" = "e9ecf8da70518a4ff852baf36c9eac369762a4568ba3cd5078fa894303e39735";
    "linux-arm64" = "35ef2685c4f679b5c4610ef56b30a680b6d595b958b4fa5ec0bfa2852195f345";
    "linux-x64" = "5155bdca27f754aba0d2fe2f80336f5fd4793224561c234a723f0ccef654a8e8";
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
