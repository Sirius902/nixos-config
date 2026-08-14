final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.232";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "7b39c1588df919d001dea3ffd5651adb682f2451b5a0e18d42d4233296b53cc7";
    "darwin-x64" = "aa3d606d7bf0ea9739a6d0de11810e72a662e7a4e5061d67ee7f8bc47c8890f9";
    "linux-arm64" = "20797ebc644dfc47a69865c46d5cf702c7dbedd48d4268063b8828ebd55b39d0";
    "linux-x64" = "61d23f8749136907d586d5b11831ea8a5234d4c1dea40a5e55c33b52e204c6d1";
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
