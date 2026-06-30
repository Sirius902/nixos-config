final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.196";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "6fc6e61ab7582c2bf241225ff90d9f79e91d69380cb9589fc9dedd3a30070f5a";
    "darwin-x64" = "32c74d66e27b9ca77aea638fc46cb11c90470bd0d294b2a981065da8896d1ee0";
    "linux-arm64" = "05aa9189d335d1e921ca9608acd699193e661559aff56704456ce5bda6fd4dd8";
    "linux-x64" = "eb933c6dd5534db89b83ba09009d5c0932bd1395f7e3bb0f34ba37eec37bbade";
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
