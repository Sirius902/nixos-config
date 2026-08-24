{
  python3,
  runCommand,
}: {
  pack,
  src,
  otr,
}:
runCommand "${pack.name}-otr-test" {
  nativeBuildInputs = [(python3.withPackages (ps: [ps.mpyq]))];
} ''
  python3 ${./check-otr.py} "${src}/data/Music" "${pack}/${otr}"
  touch $out
''
