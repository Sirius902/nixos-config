final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.178";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "473495d0c15d6616cd0870480db5eb8aa0402fe4f8ead3277a1b521e94110309";
    "darwin-x64" = "e6c5f5eec2b4d18f6234c3ba500e285f07a2e5ffb4c67d4ba0494c28c70dfe79";
    "linux-arm64" = "8e57484f5c08093117cfe6225529f8977877eea04bb3463f4e228aa7438349b3";
    "linux-x64" = "17ed1a983a49404c4673de286419a8fd6617c92440a2e0f789bcc413a3b14de1";
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
