final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.153";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "449d9c89d7a63b1d427d912a7bd6e6f23f9a7b363866697c9fa9a0012546b254";
    "darwin-x64" = "4b90521c64b728caabe221737ce8a83d362ef0852eee7d789f014f7ff73ce97b";
    "linux-arm64" = "6277fbbea72228a069e4719fc3e5fa36f16749247a2321c520dae93e83e92d9c";
    "linux-x64" = "214f603f31942162dac9a65f18d43b3ac646ae215240fad481c4aad6c60f2e38";
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
