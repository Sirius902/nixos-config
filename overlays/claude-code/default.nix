final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.227";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "7432511ba3be818e01f23f6eef8630d214a8b618451e188c3c7d61a987eef6c7";
    "darwin-x64" = "14484fb9a0480b6b638230685a7d9a248a5339b384a162e0df127e4a4a07249b";
    "linux-arm64" = "db47335532cbcab67a4b3ab16d8f3f77976bf85d53c7d79f8296538aa22bfce6";
    "linux-x64" = "6832dc3f1797b890b71116e5f2dbbf9a83fd3d0498c235b4b0f9cd0e6e499ad6";
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
