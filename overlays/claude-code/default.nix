final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.228";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "43484b1352cef03a08346f36ef0437755b1aad646ab9313ce187857b794b7247";
    "darwin-x64" = "7852f1ae0efb64d46d77a57d8852daddc4a6ffb58aeda6267bd3f3428adc09b3";
    "linux-arm64" = "2664006219497bf7021ac43156519cd42eda64ceb2a66f434ecab83e7831f942";
    "linux-x64" = "d535985e6941a3eb00179ccd7f52ceb0c6623a0305a518ebc4e6514f84a94c99";
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
