final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.191";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "99fdfb552a5260e649aedd06c024d0a4105b09cefec0bf67d558e017ee66c400";
    "darwin-x64" = "6e83aad5fc4fd459fd74539cda06d2279105eac2befc603d2fba6494974cb2a4";
    "linux-arm64" = "1a31a7cbcfd784f8c073bfc8a0a1583fb6e93e60ef70b76d7fcf663ffed8949b";
    "linux-x64" = "1038dba88bdf1b80941dc3e383e93b088325b00497329ac50da460c8786d5bee";
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
