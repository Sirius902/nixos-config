final: prev: let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.229";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  checksums = {
    "darwin-arm64" = "d732f0ba0a539c58c2ffcaef06ed03b4e523726f0cb6cc27b3a5b7e7ae0a7a21";
    "darwin-x64" = "1cb62183e9f89ea21eb4950b84896fa7101182c7dfcbbe92e7a293f0b20ba541";
    "linux-arm64" = "ba53130acbda3ddb00b3dd5641f11733867f5d837a258b7e6ccef4927cc1a509";
    "linux-x64" = "200338139a3df04a9ad22233837d1fb53fb6dffa21cd82e47559bfaa115acc1b";
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
