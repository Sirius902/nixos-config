final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.212";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "09ecba2ab2df9b6ee5b0695e26f65dea60fb3b6af3d3542ee09f466838d1e574";
    "darwin-x64" = "7681a0634c89fa4474e53c0c794e992944aebf3409a7a2b87ea9f9b0194ea341";
    "linux-arm64" = "66e88634a8573a002702e6a9de0d80cb9bb7c9072f9e6f4486778539057dfd3c";
    "linux-x64" = "044a88cf3a5180776617fd3da1238dcbf9141ddec449a39cf7d2af1ac78e684e";
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
