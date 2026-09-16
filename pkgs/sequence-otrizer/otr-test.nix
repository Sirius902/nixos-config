{
  python3,
  runCommand,
}: {
  pack,
  src,
  otr,
  music ? "data/Music",
  format ? ".ootrs",
}:
runCommand "${pack.name}-otr-test" {
  nativeBuildInputs = [(python3.withPackages (ps: [ps.mpyq]))];
} ''
  python3 ${./check-otr.py} "${src}/${music}" "${format}" "${pack}/${otr}"
  touch $out
''
