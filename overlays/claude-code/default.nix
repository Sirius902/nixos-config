final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.142";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "772021afa051160b97e04d379738df84d4cacd311e8c199a325fb013b3eaa448";
    "darwin-x64" = "d00bc6fb38d0837ce811cc862a3b6822795b33dbce8361703b1e5e903bd240fd";
    "linux-arm64" = "767b13fc28763ca9d663b00f90e501f134b356f1b72dcf0eea59b7e3bed86411";
    "linux-x64" = "1249a1dadfe2d48f320bd4e1b657a1a0d82435da76deb11ce509822407cf24ec";
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
