final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.179";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "af2a2d0cb99b0e8b094bc5dbe114ed2d5b2d27ba440987ef6f2f209da9954253";
    "darwin-x64" = "a0ad60761294bd208eda6cb0fd8e896c64397c8d317546a696c5e627782ec8cb";
    "linux-arm64" = "25d2eba2351df153f872a8e19289f5042a26b430cd446564bd92a0dec5d681cd";
    "linux-x64" = "6d8422de5ac8ac2077b20e2a6307083f85609aaf45f8c783ec2f7d71e8781e70";
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
