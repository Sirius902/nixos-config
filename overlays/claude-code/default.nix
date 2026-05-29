final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.157";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "10f398510f0e6bd7c677ee25cfc698601bf8b1ec89658f823fa23a2f80a8a73f";
    "darwin-x64" = "33b0e60e40351210f1bbb36a9478ce125474184ce0b6871f685f587f0be1b29a";
    "linux-arm64" = "57223365cbe16546fb4c0e28912b3f8cb61cac2b5ccca84b71719d9f133286bf";
    "linux-x64" = "3215501f8cfee9a70601c2fbc2c84e9d020e4e7148a0b8b8264f4d8c026bc64b";
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
