final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.186";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "463a79cc34a9787cff1b3361b4ec9e2dff928c18b077f41f0bb412e4cda78637";
    "darwin-x64" = "9e17e23d451cbbc64cf4b9536c1d25efd86808512617c855091fa608f77c9899";
    "linux-arm64" = "817e5ff483568b78c49171be317b9b9190cade77248a5776e912789312961cb6";
    "linux-x64" = "6a6d5d23486597c93138941c9b68caa0fbcd2dcedbf49e29a9c8d83e3a1cb329";
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
