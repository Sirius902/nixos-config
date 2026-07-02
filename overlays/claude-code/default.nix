final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.198";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "ab6f7ee109816ede414f7c285446633f805b623aa609f425609a64266451d61e";
    "darwin-x64" = "280b6cfc60dacc4caed31af1249e53c259c01759556e60633944c02405c82dd0";
    "linux-arm64" = "99b50a6f2b1f3ef07bcaf1e58a2f9883c470c84e428afa321972b1aa20372e9a";
    "linux-x64" = "7066af42a5fe93038c13af5072d4c034dc3928092cb121fdd892c76b94b6b84d";
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
