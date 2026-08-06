final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.223";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "fcbe0b8d47570c501302dd1ad31cc26ac2810f022c45fa253936a6961dee32bf";
    "darwin-x64" = "350e657428a6d34f7cf71f6738c5ebb6a1952ccb12fc1747f64297e065b1846f";
    "linux-arm64" = "60e83d8db0e894d0e54413e5e7daa256d180db660f51e139a51b614fc30cf3ac";
    "linux-x64" = "98226474f802e3094d6a86c5ade8883c16206d0fcb5c400b7401c800063e99d7";
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
