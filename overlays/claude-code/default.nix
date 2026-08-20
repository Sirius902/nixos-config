final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.238";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "1c196c456373b57818ae87df84aecee96cb659448c0d6a6bbb401ac5758431b2";
    "darwin-x64" = "d10bc7bb1720435f8830aa3ee74085f09348d2b1a2a152bdee251b770d76cc73";
    "linux-arm64" = "28d736120a6b14c5eae1ad1470e73371818c9c2fa41e0b3c7040207aa2d4edee";
    "linux-x64" = "0933b286cf94e1b2504b35ac165ab76b8f822735d53371c56393988c23040d58";
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
