final: prev: {
  moonlight = prev.moonlight.overrideAttrs (prevAttrs: {
    version = "1.3.34";
    src = prevAttrs.src.override {
      hash = "sha256-0cTdx51J3PwiZiIZygrgxucZp0dcqqp8NWFwoRdzJ4A=";
    };
    pnpmDeps = prevAttrs.pnpmDeps.override {
      hash = "sha256-9Auv+R8YIPQFFaplahEl4eNKqskxOH50nQb+oLkjtNo=";
    };
  });
}
