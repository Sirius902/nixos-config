# shellcheck shell=bash
# Read-only checks that a VM's data is in place, run as root before any other
# unit of the VM starts. Prints the command that fixes each problem.
# Usage: vm-preflight <name> <dataset> <path> <owner>

name=$1
dataset=$2
path=$3
owner=$4

problems=0

# problem <description> <command>...
problem() {
  problems=$((problems + 1))
  printf '\n- %s\n' "$1"
  shift
  printf '      %s\n' "$@"
}

finish() {
  if [ "$problems" -eq 0 ]; then
    echo "vm-$name preflight: $dataset is mounted at $path and ready"
    exit 0
  fi
  printf '\nvm-%s stays off until that is fixed.\nRunbook: docs/microvms.md\n' "$name"
  exit 1
}

zget() { zfs get -H -p -o value "$1" "$dataset"; }
exists() { zfs list -H -o name "$1" > /dev/null 2>&1; }
has_files() { [ -d "$path" ] && [ -n "$(ls -A "$path")" ]; }

# 1. The dataset is mounted at its path. / is a tmpfs, so data written to an
#    unmounted path would land in RAM.
if ! exists "$dataset"; then
  if has_files && ! mountpoint -q "$path"; then
    problem "$path holds files but isn't dataset $dataset. Move them onto a new dataset:" \
      "doas mv $path $path.old" \
      "doas zfs create -o mountpoint=$path -o setuid=off -o devices=off -o exec=off $dataset" \
      "doas rsync -aHAX $path.old/ $path/" \
      "doas chown -hR $owner: $path" \
      "# once the server works from the dataset: doas rm -rf $path.old"
  else
    fixes=()
    parent=${dataset%/*}
    if [ "$parent" != "$dataset" ] && ! exists "$parent"; then
      fixes+=("doas zfs create -p -o canmount=off $parent")
    fi
    fixes+=("doas zfs create -o mountpoint=$path -o setuid=off -o devices=off -o exec=off $dataset")
    problem "dataset $dataset doesn't exist. Create it:" "${fixes[@]}"
  fi
  finish
fi

if [ "$(zget mountpoint)" != "$path" ]; then
  problem "dataset $dataset mounts at $(zget mountpoint), not $path:" \
    "doas zfs set mountpoint=$path $dataset"
  finish
fi

if [ "$(findmnt -n -o SOURCE --mountpoint "$path" | tail -n 1)" != "$dataset" ]; then
  fixes=()
  if has_files; then
    fixes+=("doas mv $path $path.old")
  fi
  if [ "$(zget canmount)" = off ]; then
    fixes+=("doas zfs set canmount=on $dataset")
  fi
  fixes+=("doas zfs mount $dataset")
  problem "dataset $dataset isn't mounted at $path:" "${fixes[@]}"
  finish
fi

# 2. Nothing the VM writes can act as a setuid binary, a device or a program
#    on the host.
props=()
for prop in setuid devices exec; do
  if [ "$(zget "$prop")" != off ]; then
    props+=("$prop=off")
  fi
done
if [ "${#props[@]}" -gt 0 ]; then
  problem "dataset $dataset doesn't have ${props[*]}:" "doas zfs set ${props[*]} $dataset"
else
  options=,$(findmnt -n -o OPTIONS --mountpoint "$path" | tail -n 1),
  for opt in nosuid nodev noexec; do
    if [[ $options != *",$opt,"* ]]; then
      problem "$path is mounted without $opt although the dataset's properties ask for it; remount it with the VM stopped:" \
        "doas zfs unmount $dataset" \
        "doas zfs mount $dataset"
      break
    fi
  done
fi

# 3. Everything is the owner's. Through the VM's view anything else belongs to
#    nobody, so the server could not write it.
# A file vanishing mid-walk makes find fail; what it did see still counts.
others=$(find "$path" -xdev -mindepth 1 ! -user "$owner" -printf '%u  %P\n' || true)
count=0
if [ -n "$others" ]; then
  count=$(printf '%s\n' "$others" | wc -l)
fi
top=$(stat -c '%U:%G' "$path")
if [ "$count" -gt 0 ]; then
  examples=$(printf '%s\n' "$others" | sed -n '1,5s/^/        /p')
  problem "$count entries under $path aren't yours, for example:
$examples
    Fix it with the VM stopped:" "doas chown -hR $owner: $path"
elif [ "${top%%:*}" != "$owner" ]; then
  problem "top dir $path is owned by $top; it should be yours:" "doas chown $owner: $path"
fi

finish
