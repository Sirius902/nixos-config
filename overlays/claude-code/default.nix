final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.195";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "8b45adad93f336ab95f33e714494b19fd3377a494eb05c122c8677bc895876ad";
    "darwin-x64" = "7eb8716e6d6e6a278d13158793529336290837fca457facfec656f1b1a287c60";
    "linux-arm64" = "b02279999058dc80a0e1c5d39463d1545a178615492f84139aac8d61214a7e9a";
    "linux-x64" = "8323e70125063147a4478b957745d835a87e5e72ffd25b838ea9a841c03e6a37";
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
