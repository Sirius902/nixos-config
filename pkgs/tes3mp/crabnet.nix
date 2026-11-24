{
  lib,
  gcc14Stdenv,
  fetchFromGitHub,
  fetchpatch,
  cmake,
}:
gcc14Stdenv.mkDerivation {
  pname = "crabnet";
  version = "0-unstable-2020-01-19";

  # NOTE(Sirius902) Moves only with a TES3MP release, since official clients'
  # network protocol depends on it.
  src = fetchFromGitHub {
    owner = "TES3MP";
    repo = "CrabNet";
    rev = "19e66190e83f53bcdcbcd6513238ed2e54878a21";
    hash = "sha256-WIaJkSQnoOm9T7GoAwmWl7fNg79coIo/ILUsWcbH+lA=";
  };

  patches = [
    # Include <cstdint> for GCC 13 https://github.com/TES3MP/CrabNet/pull/18
    (fetchpatch {
      name = "include-cstdint.patch";
      url = "https://github.com/TES3MP/CrabNet/commit/3ec9a338a7cefd5cc751c9d29095cafa4c73be20.diff";
      hash = "sha256-zE87icjX9GSnApgKQXj0K4IjlrReV/upFLjVgNYkNfM=";
    })
  ];

  __structuredAttrs = true;
  strictDeps = true;

  nativeBuildInputs = [cmake];

  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
    (lib.cmakeBool "CRABNET_ENABLE_DLL" false)
  ];

  meta = {
    description = "TES3MP's fork of the RakNet networking library";
    homepage = "https://github.com/TES3MP/CrabNet";
    license = lib.licenses.bsd2;
    maintainers = with lib.maintainers; [sirius902];
    platforms = lib.platforms.linux;
  };
}
