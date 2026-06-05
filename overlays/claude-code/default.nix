final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.163";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "c7582e926e8fe459dbd9743f19ccb75500e3b455c722902d1aa587a74fb1fa7c";
    "darwin-x64" = "a409fc60ccd6789f47532791ed23ca048774cfbd0b0a16f9f57dbbf9240fda7c";
    "linux-arm64" = "ca0010a80e3c4749e59c6e8429ec4a4e2ecbaafac36d3535636e04369bbb87c0";
    "linux-x64" = "5dddcb2c091da60cf9b1bef782e6c78a7fada2f2cd3db4f131c9ebc2478fd447";
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
