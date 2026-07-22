final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.218";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "71abaff59312c9a9b6a1d818365048b42e4e95cc521a823660eded3e0880d9b7";
    "darwin-x64" = "9862b74a083e8a4ed572f99cbd4895185e0dd5a0a601affb0fb8e43d8d1f40e6";
    "linux-arm64" = "295fd30481bd03b38450fdec2a6e25bb6472c2074f04b0c4a566cd5988f230bf";
    "linux-x64" = "e12071751a9336b8af1012c103358ff04ac18f9aaff4a738cff7ba5cdfaf63f2";
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
