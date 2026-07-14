final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.208";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "051c7f28871b158132ac03a6140f2f2ab4046b18ecc4f7a91a2ac4d54774551e";
    "darwin-x64" = "804ea81cb1e2b5f883c2490fc668fd19ce185e37b9b9991f5832d38dc62e2ff4";
    "linux-arm64" = "81e5dd48377bfd3cb733820e4e23f2294c925cba1e52dbeada69f46929f0c4a6";
    "linux-x64" = "125372839bc827ca24dd72382627b291fbca615408d732fe3291bc16723ce7f3";
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
