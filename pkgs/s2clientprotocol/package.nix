{
  python3,
  lib,
  fetchFromGitHub,
  protobuf,
}:
python3.pkgs.buildPythonPackage {
  pname = "s2clientprotocol";
  version = "5.0.14.93333.0";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "Blizzard";
    repo = "s2client-proto";
    tag = "1.2.0";
    hash = "sha256-Rn1gjivfqBxBRpeLDn46PkpOn2drPkd+GmiwA4S4O8I=";
  };

  nativeBuildInputs = [protobuf];

  meta = {
    description = "StarCraft II - client protocol";
    homepage = "https://github.com/Blizzard/s2client-proto";
    license = lib.licenses.mit;
    maintainers = [];
  };
}
