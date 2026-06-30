final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.197";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "8cc0c4d1e4eb1dca3b0cc92ab02ee3505de764e023f8c901761c167b72041fb8";
    "darwin-x64" = "5e8a57cc7a92377f0744fa4c79191cf93d4b26c79cb919b07a407511fed1be26";
    "linux-arm64" = "fb48473c467c27615ac799a754f4ef0b68c363e4596cefbb59c3815d51a0cc8a";
    "linux-x64" = "f54e69cbc89b2da61a415700af7ff52a147e862517d4f1b0eecf768448cf7f83";
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
