final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.168";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "377f0ecedba8246bdabdf312ce8b7cc8ae1160997b26f5edca352a4a8d61dc78";
    "darwin-x64" = "688f3d9fa0955878c291a58febe9e4daa061326da217ada740d97c5e17634a26";
    "linux-arm64" = "40d50e7c45742aaa3707fa3628d7f765c55ed503108b6f100513e38d32477aa0";
    "linux-x64" = "e2f7cb50442bdee21bf2686ef3725a6af187a204e46c4af5c12d0f6d76326485";
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
