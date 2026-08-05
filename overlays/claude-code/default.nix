final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.222";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "c66a6cc6fa2e8145bb1a6e77831f2caf4b83690ff04650500dfa6e2c05ca997c";
    "darwin-x64" = "36bfc6482a25730dbb1cee72589e522c66c45a4dc9ebfdd8a76a8113b01b6188";
    "linux-arm64" = "a04be0a8d7fe0259571ab7411d51d85658d71a4a26ce62b60c908290372e6016";
    "linux-x64" = "10caae8f22b915c26bfff0e013a4d45608c4f1ae287583626569156f447730e5";
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
