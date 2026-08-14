final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.233";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "bc466b6cde63edafc773f471a1fb98787fabb31f52240c8616ce7e1f587b212d";
    "darwin-x64" = "8b3ae18df411098ce55705c4bb151e9c97e34df55fe379c7b6b3122a69f0ea74";
    "linux-arm64" = "42df1841f74e9b2ac13f2c1a2a820ef6b9ac5b2efb8646bb25c9a92b8bd69194";
    "linux-x64" = "55d281096f57d411ebbdd94dbf5e9ff3accb7c05713e37348c2c11d4b83bf9d9";
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
