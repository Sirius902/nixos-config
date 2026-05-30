final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.158";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "536a0517fa64d48ddcbc8eb511a3d08027d47e06d148872332a8041d72c22768";
    "darwin-x64" = "b7b33293702fb8e0a119b795d5af5178bd346fb46d4d7f161336d521f62d1451";
    "linux-arm64" = "98807675a3ed5b7b775f7eaa81eda32cba2810b97e9db9f6f98d7bd658cec00e";
    "linux-x64" = "dd27008acd42700bac5762652ec83ff604bf9ae0786d4dde55d57a6866017fbe";
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
