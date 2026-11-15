# shellcheck shell=bash
# vm: run and inspect this host's microVMs. See docs/microvms.md.

inventory=@inventory@

declare -A ports memory cpus partners runner autostart dataset datapath
names=()
while IFS='|' read -r n p m c pa r a d dp; do
  names+=("$n")
  ports[$n]=$p
  memory[$n]=$m
  cpus[$n]=$c
  partners[$n]=$pa
  runner[$n]=$r
  autostart[$n]=$a
  dataset[$n]=$d
  datapath[$n]=$dp
done < "$inventory"

usage() {
  cat << EOF
usage: vm <command> [<name>]

  list               every VM, its state and ports
  status <name>      state, ports, memory, partners, pending update
  start <name>       start it, stopping any VM that shares a port with it
  stop [-f] <name>   shut it down; -f kills it at once, losing unsaved data
  restart <name>
  check <name>       run its preflight and print the result
  logs [-f] <name>   its console, guest journal and host-side units
  console <name>     attach to the server console (Ctrl-D detaches)
  shell <name>       root shell in the guest

VMs: ${names[*]}
EOF
  exit "${1:-0}"
}

die() {
  printf 'vm: %s\n' "$*" >&2
  exit 1
}

known() {
  [ -n "${1:-}" ] || usage 1
  [ -n "${ports[$1]+set}" ] || die "no VM named '$1' (VMs: ${names[*]})"
}

state() { systemctl show --property=ActiveState --value "vm-$1.service"; }

pending() {
  local booted
  booted=$(cat "/run/vm/$1/runner" 2> /dev/null) || return 1
  [ "$booted" != "${runner[$1]}" ]
}

# Output of the unit's last run, waiting briefly for journald to catch up.
last_run() {
  local id out _
  id=$(systemctl show --property=InvocationID --value "$1")
  [ -n "$id" ] || return 0
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    out=$(journalctl --no-pager --output=cat "_SYSTEMD_INVOCATION_ID=$id")
    [ -n "$out" ] && break
    sleep 0.1
  done
  printf '%s\n' "$out"
}

say_conflicts() {
  local entry partner
  for entry in ${partners[$1]}; do
    partner=${entry%%=*}
    if [ "$(state "$partner")" = active ]; then
      echo "stopping $partner (${entry#*=})"
    fi
  done
}

# Runs the preflight; when it refuses, prints why.
preflight() {
  systemctl start "vm-$1-preflight.service" && return
  if [ "$(systemctl show --property=Result --value "vm-$1-preflight.service")" = exit-code ]; then
    last_run "vm-$1-preflight.service" >&2
  fi
  return 1
}

run() { # <verb> <name>
  # First on its own, so that a VM it refuses doesn't stop a partner.
  preflight "$2" || exit 1
  say_conflicts "$2"
  systemctl "$1" "vm-$2.service" || die "see 'vm logs $2'"
}

# Kills the VM outright, as pulling its plug would. A clean stop waits for the
# server to save, and a server still loading reads its console only once done.
kill_vm() {
  case $(state "$1") in
    inactive | failed)
      echo "$1 is not running"
      return
      ;;
  esac
  echo "vm: killing $1 without a shutdown; whatever its server hadn't saved is lost" >&2
  systemctl kill --signal=SIGKILL "vm-$1.service"
  for _ in {1..50}; do
    case $(state "$1") in
      inactive | failed) return ;;
    esac
    sleep 0.1
  done
  die "$1 is still going down; see 'vm status $1'"
}

list() {
  local n s any=
  printf '%-12s %-14s %-24s %s\n' NAME STATE PORTS AUTOSTART
  for n in "${names[@]}"; do
    s=$(state "$n")
    if [ "$s" = active ] && pending "$n"; then
      s="$s*"
      any=1
    fi
    printf '%-12s %-14s %-24s %s\n' "$n" "$s" "${ports[$n]}" "${autostart[$n]}"
  done
  if [ -n "$any" ]; then
    echo "* update pending; restart the VM to apply it"
  fi
}

status() {
  local n=$1 s since used exclusive=() entry
  s=$(state "$n")
  if [ "$s" = active ]; then
    since=$(systemctl show --property=ActiveEnterTimestamp --value "vm-$n.service")
    printf '%s: active since %s\n' "$n" "$since"
  else
    printf '%s: %s\n' "$n" "$s"
  fi
  printf '  %-10s %s\n' ports "${ports[$n]}"
  used=$(systemctl show --property=MemoryCurrent --value "vm-$n.service")
  if [[ $used =~ ^[0-9]+$ ]]; then
    printf '  %-10s %s MiB, %s in use\n' memory "${memory[$n]}" "$(numfmt --to=iec "$used")"
  else
    printf '  %-10s %s MiB\n' memory "${memory[$n]}"
  fi
  printf '  %-10s %s\n' cpus "${cpus[$n]}"
  for entry in ${partners[$n]}; do
    exclusive+=("${entry%%=*} (${entry#*=})")
  done
  if [ "${#exclusive[@]}" -gt 0 ]; then
    printf '  %-10s %s\n' exclusive "${exclusive[*]}"
  fi
  printf '  %-10s %s\n' autostart "${autostart[$n]}"
  printf '  %-10s %s at %s\n' data "${dataset[$n]}" "${datapath[$n]}"
  if [ "$s" = active ]; then
    if pending "$n"; then
      printf '  %-10s %s\n' update "pending; restart to apply"
    else
      printf '  %-10s %s\n' update "none pending"
    fi
  fi
}

admin_socket() {
  local sock=/run/vm/$1/vsock.sock
  [ "$(state "$1")" = active ] || die "$1 is not running"
  [ -w "$sock" ] || die "no access to $sock; vm-admin membership takes effect in a new login session"
  printf '%s\n' "$sock"
}

cmd=${1:-}
[ "$#" -gt 0 ] && shift
case $cmd in
  list)
    list
    ;;
  status)
    known "${1:-}"
    status "$1"
    ;;
  start | restart)
    known "${1:-}"
    run "$cmd" "$1"
    ;;
  stop)
    force=
    if [ "${1:-}" = -f ]; then
      force=1
      shift
    fi
    known "${1:-}"
    if [ -n "$force" ]; then
      kill_vm "$1"
    else
      systemctl stop "vm-$1.service"
    fi
    ;;
  check)
    known "${1:-}"
    preflight "$1" || exit 1
    last_run "vm-$1-preflight.service"
    ;;
  logs)
    follow=()
    if [ "${1:-}" = -f ]; then
      follow=(--follow)
      shift
    fi
    known "${1:-}"
    exec journalctl "${follow[@]}" \
      --unit="vm-$1.service" --unit="vm-$1-preflight.service" --unit="vm-$1-share.service" \
      --unit="vm-$1-fs-data.service" --unit="vm-$1-fs-secrets.service" --unit="vm-$1-net.service"
    ;;
  console)
    known "${1:-}"
    sock=$(admin_socket "$1")
    echo "attached to $1's console; Ctrl-D detaches" >&2
    { printf 'CONNECT 1024\nconsole\n'; cat; } | socat - "UNIX-CONNECT:$sock" | sed -u '1{/^OK /d}'
    ;;
  shell)
    known "${1:-}"
    sock=$(admin_socket "$1")
    exec ssh "vsock-mux$sock" "${@:2}"
    ;;
  -h | --help | help | "")
    usage
    ;;
  *)
    usage 1
    ;;
esac
