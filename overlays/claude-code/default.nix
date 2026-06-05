final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.165";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "19ed536dd0e94dade3f8c49c3c6ddeff22b06f5d5c86b30f1c88eeb9a04f45e5";
    "darwin-x64" = "3cb50cb3c9a065bd2d88250ceb3f2647ce16f89f384dede1f7de2676fa526af0";
    "linux-arm64" = "ff2e060827f9f0214a77133206c4539a6477ec1f4fddb492b02255a0679642fd";
    "linux-x64" = "d34b0caadd25eb82d8e08ca103b648291b4defef53193f572847a736e2aaf4d8";
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
