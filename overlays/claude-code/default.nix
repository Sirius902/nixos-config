final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.215";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "90608b5c5ab504e96e77365cea6203d046e291d59b2bb42cf28dcb2ccdf9dd58";
    "darwin-x64" = "1ef5f5e56ede9f7765a9bef654ece6045dba58f48b7f5b699765375953d52b6b";
    "linux-arm64" = "2b43a3d5b0787217e5d7381fad42c7314292546fe9db9eb8b9b379de90509b30";
    "linux-x64" = "c1efffaaf370aa187cb6a09dd93d4e511c646899b0078476f83791b664bde7fe";
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
