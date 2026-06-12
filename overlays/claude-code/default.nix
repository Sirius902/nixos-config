final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.175";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "6b75bf132c866ed409bf913c318ca32011e73ffb12d3cd67ecc37bc4ee9ec65d";
    "darwin-x64" = "3770f2cb42d3f776e62a59aa16230843dc7b8422b36be9b1532e02a6e92e7fa8";
    "linux-arm64" = "360f1f6f43ec26d9bb6e20e487bf44b753d9b8407e89e74bfeeb79707399f435";
    "linux-x64" = "4fc72fa6090c9a03f1850e1b1ccb3d6806bf802b67e3cb9dc5f2ced4b7ed5ca1";
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
