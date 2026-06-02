final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.162";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "2d407dd2a63243ac900f64331589b9fcd29a2159a73289070af685f4085a17d2";
    "darwin-x64" = "53f2749bf24e5a80b23b017d0877f61c9894a3c06222141515b37a94c6051d41";
    "linux-arm64" = "eca2a603dfebc3426a8469cbe797f9df95245738bc1c20ec842fc8f80af4010d";
    "linux-x64" = "947a49b0de8688f6a74a6e753c24771ff3ddd17b2a6dae85f36304ec514e61d1";
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
