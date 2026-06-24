final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.190";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "1fa59529c233914fdd9d42816a74ecf300eefa14c3d118d4ecba2f0f16fc5741";
    "darwin-x64" = "4eca48431a43c5540c53657964be604f301d38c02b244ca7c05da18f84bb5c85";
    "linux-arm64" = "e7305203e7d78a6bfecb94f7973b0ee4a71a3ba67c8028c98b293cf571900b68";
    "linux-x64" = "0684e28517cc785ab8d19feb5dad3381eab4abc97bf6fce07bc534dc88040b27";
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
