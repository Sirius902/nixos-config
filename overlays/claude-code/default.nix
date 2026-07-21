final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.217";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "5840c777fd47115e9ca276e165563c6e121e7c7e2b4d86598e0025f8cc37de56";
    "darwin-x64" = "8387a6fd44edfd40d7e74c5fdc3270a15f5e6b1b58c7c6fee560e70d3d1943da";
    "linux-arm64" = "40c53507ac669c1d438366c19760c22f52748a06e50e0fc0e353d2cb73425597";
    "linux-x64" = "2630fc5dc6db61bc03f86b95daf47766e5ed5b61873f7bb7cfea764c5ac5a9ba";
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
