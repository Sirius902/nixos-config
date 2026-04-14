{
  lib,
  buildGoModule,
  fetchFromGitHub,
  testers,
}: let
  core-src = fetchFromGitHub {
    owner = "fvs-lab";
    repo = "core";
    rev = "305bcbe730ec54649414bc41a424044ef38c37a4";
    hash = "sha256-IBNNa5LGjtPNWhI0PC0NX8rK8z2LnfzOpKpDE1TZQhw=";
  };

  patchCore = ''
    cp -r ${core-src} core
    substituteInPlace go.mod --replace-fail "../core" "./core"
  '';
in
  buildGoModule (finalAttrs: {
    pname = "fvs2";
    version = "0.1.5";

    src = fetchFromGitHub {
      owner = "fvs-lab";
      repo = "fvs2";
      tag = "v${finalAttrs.version}";
      hash = "sha256-YFtHWtkAPxHT2BqJyyKpPPwkrYyDoFEHq76mNPczJjI=";
    };

    postPatch = patchCore;
    overrideModAttrs = _: {postPatch = patchCore;};

    vendorHash = "sha256-WQptq8FKcA4vLIs3vImgG0gVW4JDPvA2Dcez9YOZVfM=";
    subPackages = ["cmd/fvs2"];

    passthru.tests.init-and-status = testers.runCommand {
      name = "${finalAttrs.pname}-init-and-status-test";
      nativeBuildInputs = [finalAttrs.finalPackage];
      script = ''
        dir=$(mktemp -d)
        fvs2 init --path "$dir"
        output=$(fvs2 status --path "$dir")
        echo "$output"
        echo "$output" | grep -q "branch=main"
        echo "$output" | grep -q "dirty=false"

        echo "hello" > "$dir/testfile"
        fvs2 commit --path "$dir"
        echo "world" >> "$dir/testfile"
        output=$(fvs2 status --path "$dir" --check-dirty)
        echo "$output"
        echo "$output" | grep -q "dirty=true"
        echo "$output" | grep -q "changed_files=1"

        touch $out
      '';
    };

    meta = {
      description = "Standalone CLI for FVS v2";
      homepage = "https://github.com/fvs-lab/fvs2";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "fvs2";
    };
  })
