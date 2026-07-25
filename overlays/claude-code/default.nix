final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.220";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "8addc857f3fe64d5a0368af9ee50321b50afb4a6918ba3ef018ab84f5dbbe081";
    "darwin-x64" = "dca7be0aa7d3d924836d440e0c6d8e3d47ef3c8e61fa5809b54b9017170ce2f3";
    "linux-arm64" = "159e4a51d796f3bf14677577100f7efb845611b1ceaf0c30cbd8d4650d942185";
    "linux-x64" = "674f61f20ff306f3100cf9200e4c36c4b70278b5bef2884549819b942a89c863";
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
