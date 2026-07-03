# Mitigations for the Intel I219-V (e1000e) "Detected Hardware Unit Hang" that wedged
# eno2 — and with it the whole host — under the atm10 microVM's forwarded traffic on
# 2026-07-02 (the NIC hung for 39 min and needed a physical power-cycle). It's an
# unfixed NIC bug (github.com/lxc/incus-os/issues/849 among many), triggered specifically
# by KVM-guest virtio forwarding, which is why native atm10 and the lightly-used
# atm10-test never hit it. Two layers: disable the offloads that trigger it, and a
# watchdog to self-recover since the fix isn't guaranteed and the host is remote. Retire
# this if the uplink moves to enp6s0 (a Realtek r8169 that doesn't have this bug).
{pkgs, ...}: {
  environment.systemPackages = [pkgs.ethtool];

  # Re-applied on every eno2 up because NetworkManager can silently re-enable offloads.
  networking.networkmanager.dispatcherScripts = [
    {
      source = pkgs.writeShellScript "eno2-disable-offloads" ''
        if [ "$1" = eno2 ] && [ "$2" = up ]; then
          ${pkgs.ethtool}/bin/ethtool -K eno2 tso off gso off gro off tx-gso-partial off || true
        fi
      '';
    }
  ];

  # A hung TX engine looks like "gateway unreachable while the link is still up" — which
  # a cable/router outage doesn't (the link drops), so that signature gates recovery:
  # reset the NIC, and only reboot as a last resort (confirmed by the kernel's hang
  # message and rate-limited, so a genuinely dead NIC can't reboot-loop).
  systemd.services.eno2-hang-watchdog = {
    description = "Recover eno2 from an e1000e Hardware Unit Hang";
    path = [pkgs.coreutils pkgs.gnugrep pkgs.gawk pkgs.iproute2 pkgs.iputils pkgs.util-linux pkgs.systemd];
    serviceConfig.Type = "oneshot";
    script = ''
      set -u
      state=/run/eno2-hang-watchdog.fails
      stamp=/var/lib/eno2-hang-watchdog/last-reboot
      gw=$(ip route show default dev eno2 2>/dev/null | awk '/default/{print $3; exit}')

      if [ -z "$gw" ] || [ "$(cat /sys/class/net/eno2/carrier 2>/dev/null)" != 1 ]; then
        rm -f "$state"; exit 0
      fi
      if ping -c1 -W2 "$gw" >/dev/null 2>&1; then
        rm -f "$state"; exit 0
      fi

      fails=$(( $(cat "$state" 2>/dev/null || echo 0) + 1 ))
      echo "$fails" > "$state"
      logger -t eno2-hang-watchdog "gateway $gw unreachable, link up (#$fails)"

      if [ "$fails" = 3 ]; then
        logger -t eno2-hang-watchdog "resetting eno2"
        ip link set eno2 down; sleep 3; ip link set eno2 up
      elif [ "$fails" -ge 8 ] && dmesg 2>/dev/null | tail -n 80 | grep -q "Detected Hardware Unit Hang"; then
        now=$(date +%s); last=$(cat "$stamp" 2>/dev/null || echo 0)
        if [ "$(( now - last ))" -gt 1800 ]; then
          mkdir -p "$(dirname "$stamp")"; echo "$now" > "$stamp"
          logger -t eno2-hang-watchdog "e1000e hang unrecovered by reset; rebooting"
          systemctl reboot
        fi
      fi
    '';
  };
  systemd.timers.eno2-hang-watchdog = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "3min";
      OnUnitActiveSec = "60s";
    };
  };
}
