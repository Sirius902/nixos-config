final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.185";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "a280c23b210525218f5bd86f001c9dbc89b9e07410175c5a9355044bfadc0af1";
    "darwin-x64" = "ade7a13c3027f754b4cdac80bcdd6ba470f7becb27cdcf8b6ba9a70cf9e77af7";
    "linux-arm64" = "db880812272504455df73160d92fadf9370eda684c219cebf8e62b0a262cb2f8";
    "linux-x64" = "e1246338699f04ee0e627dee3f6d4ed7a0bab48e0514bde69c6dad43bc303952";
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
