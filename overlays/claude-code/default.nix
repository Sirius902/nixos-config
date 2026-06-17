final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.181";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "c4d833b04606cef9b6eab3ad255ed2e1448f87dea2bc00ff5acf77b57df6e94d";
    "darwin-x64" = "353798bcdc49a52a666645370e1c48a84fe837d93bf9d954c19338dca7260ddd";
    "linux-arm64" = "1393f993533e08d5c96245504750a7fcfe37490a5f44eec35b0beac3d709dab9";
    "linux-x64" = "35ffd4e9d9a86395d0ba4e05f8b23bf098bfeab95e97deacd6537909d1324e9c";
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
