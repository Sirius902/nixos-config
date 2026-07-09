final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.205";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "33e28624c5ae84f2bd7d2d8761e5d2e77997ba965cb11b6448de6b6e2c566f9c";
    "darwin-x64" = "4299a3f48551ef365f2d056f24d87e84b822c4c10b6acc46979446b7b5c60ceb";
    "linux-arm64" = "c1874c85bcd3a88b70439fd50ff5910b7e6ac5371c14dd49d4ccc2878a592d09";
    "linux-x64" = "dd8734c0b6a503fe1d17425184e57b397c30bb0337a33f1470d9985febfe5b09";
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
