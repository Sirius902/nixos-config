final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.144";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "9886baa4ec4c455f86108464f121732193ee76e5dfceb031005f59f31276a5df";
    "darwin-x64" = "d225c07b713615ceda54cebcfb6280942b113c64dccbaa114b12204e917087f8";
    "linux-arm64" = "c8ccccbfce12d684588bd3af366394132f614dcf3c86beb2066f86bde2704513";
    "linux-x64" = "147480774472e5720fd5e83617b3e9299344e7213efa84c326b25bd5a0f20b4e";
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
