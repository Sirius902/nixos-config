final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.214";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "59796dd18e9d77f1256f367db6d28ce4bd9cd5968e402ad3a327aac36abc6dec";
    "darwin-x64" = "d979ba15662828969e5d0f39f1367798a07ef6e031b524efdad37fe7caf84010";
    "linux-arm64" = "4c38f26a57a42619ee813f15dc39fc1fa4fe0bb403215c3cdc342b58fa689c3c";
    "linux-x64" = "3c029136f7c81f54ed4a38e9d52e655aad536433dbbde50519c8c31bb646ad14";
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
