final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.145";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "368dcd9709c85534f673071e7cc8eb5422bcff367fb9bdf5ce25d9619aab7ef5";
    "darwin-x64" = "c23dc566214279d0708f4212261f023d8e63d5af5aef91638ebfdc090b3e33de";
    "linux-arm64" = "75ad61d690d79440c82b5841444e1b42caae55736af37c97dd0e068ef20ce390";
    "linux-x64" = "b3ffbc12689bfe81389d6577787fcea4cab81bd3b6bba9b719e73770b62d720e";
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
