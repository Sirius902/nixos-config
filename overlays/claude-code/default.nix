final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.235";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "83b8f806f6f2eea316cfe246628e6c23374711d868f1fd0409db551b877b7748";
    "darwin-x64" = "325a2dbc166ba8361a913ce588dce4a236789502060239acea52072bb51a54f1";
    "linux-arm64" = "cff9592faa292db0f6ac21874f151b8c3d44e23bf0ab9fd1bcca95edc3469549";
    "linux-x64" = "bfcf0ae2dbf94b2b6a106074aabf3938b9a10889c3b678e4cb5a00c03274d5d5";
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
