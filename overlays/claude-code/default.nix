final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.187";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "a59a16ba4922adab7a145728f215d042184d349f5f7e72cddb7fc114250a4ce3";
    "darwin-x64" = "7f57b6935b4246d03cb7acee90dc22153083483a267da589c5c920dd04744c36";
    "linux-arm64" = "b49be8a5e565bf2d45b50d2de62017b25462131acc9425d2fdb98b8f29c9dce2";
    "linux-x64" = "bb02fcb33626f8c599d10d8bee38585d4cf8d4225c3b497869dee7454e7bf361";
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
