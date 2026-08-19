final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.236";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "6bc4ba992d2786cbf0237c4453ca53c1fdf0c3b3d83ffa0025c0d8190ed27848";
    "darwin-x64" = "3ce6a8e016fcae45ad3f2dc78f1980600d3908c302355396a0d6bc17b5d43333";
    "linux-arm64" = "c38d37deaf1643083326c48a6acc0afb09dada126e6bda77ef1a4410ae60ca12";
    "linux-x64" = "6c8818fa22187aa555c242be4abbacc44d6b71a32ac9631ee7b2b5d12f51f752";
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
