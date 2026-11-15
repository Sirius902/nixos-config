# MicroVMs

A runbook, not a convention doc: how hee-ho's servers run, and how to add,
migrate, run and remove one. Every preflight failure points here.

Each server runs in a microVM of its own, declared in
`hosts/hee-ho/vms/<name>.nix` and run by `modules/microvms`. A VM can't see
the host's files, the LAN, the tailnet, the host itself or the other VMs. Its
data is one ZFS dataset that on disk is plainly yours (chris's); the VM sees
the same files through a view in which they're its own, so nothing ever needs
a permissions fix. Don't run git inside a server directory: files the VM
writes are yours on disk, so git would trust them.

## Adding a server

1. Declare it in `hosts/hee-ho/vms/<name>.nix` and import that from
   `configuration.nix`. `vms/rl2.nix` is the model: size, ports, OOM order,
   dataset, and the guest module that enables the server.
   - VMs that share a port can't run together; starting one stops the other.
   - `autostart = true` starts it with the host. Off by default.
   - `egress = "none"` for a server that never needs to connect out.
   - `secrets` for anything the server must not find in the Nix store; see
     [Secrets](#secrets).

2. Deploy. A switch never restarts a VM, so this is safe while others run:

   ```console
   $ nh os test -H hee-ho .#   # then check SSH and Tailscale
   $ just switch
   ```

   The first deploy adds you to `vm-admin`; open a new login session before
   using `vm console` or `vm shell`.

3. `vm start <name>` refuses until the data is in place, and prints each
   command to run. For a new server that's the dataset, then its top
   directory, which ZFS creates as root's:

   ```console
   $ doas zfs create -o mountpoint=/media/data/mc/servers/<name> \
       -o setuid=off -o devices=off -o exec=off data/mc/<name>   # Minecraft
   $ doas zfs create data/srv/<name>                            # anything else
   $ doas chown chris: <path>
   ```

   `data/srv/<name>` inherits its mountpoint and properties from `data/srv`;
   the first time, create that too:

   ```console
   $ doas zfs create -o canmount=off -o mountpoint=/media/data/srv \
       -o setuid=off -o devices=off -o exec=off data/srv
   ```

4. Fill it as yourself, with any tool. A Modrinth pack:

   ```console
   $ mrpack-install <slug> <version> --server-dir /media/data/mc/servers/<name>
   ```

   A Minecraft server also needs `eula.txt` (`eula=true`), a `server.properties`
   whose `server-port` is the declared port, and a foreground `start.sh`:

   ```sh
   #!/bin/sh
   cd "$(dirname "$0")"
   exec java -Xmx8G -Xms1G @libraries/net/neoforged/neoforge/21.1.249/unix_args.txt nogui
   ```

   Size the VM's `memory` at the heap plus about 2 GiB for the JVM and guest.

5. `vm start <name>`, then `vm console <name>` to watch it load. A mistake in
   step 4 shows up in `vm logs <name>`.

## Migrating existing data

A plain directory at the declared path: `vm start` prints the sequence that
moves it onto a new dataset (move aside, create, `rsync -aHAX` back, `chown`).
Remove the `.old` copy once the server works from the dataset.

An existing dataset elsewhere:

```console
$ doas zfs set mountpoint=<path> setuid=off devices=off exec=off <dataset>
$ doas chown -hR chris: <path>
```

`chown -hR` never follows symlinks, so it's safe on anything a VM wrote. Run it
with the VM stopped.

## Day to day

```console
$ vm list                  # every VM, its state and ports
$ vm status <name>         # memory, partners, pending update
$ vm start <name>          # names any VM it stops for a shared port
$ vm stop [-f] <name>      # -f: kill it outright, unsaved data and all
$ vm restart <name>
$ vm check <name>          # the preflight alone
$ vm logs [-f] <name>      # guest console and journal, host-side units
$ vm console <name>        # server console; Ctrl-D detaches
$ vm shell <name>          # root shell in the guest
```

No doas: starting and stopping go through polkit, the console and shell
through `vm-admin`.

`vm stop` lets the server save before the VM powers off. A Minecraft server
reads its console only once it has loaded, so a stop during loading waits for
that first. `-f` kills the VM at once, as pulling its plug would; whatever the
server hadn't saved is lost.

When a switch changes a running VM, it keeps running the old one and `vm list`
marks it; `vm restart <name>` applies the update.

Players' real addresses reach the server. Connections from hee-ho itself to
`127.0.0.1` arrive from 10.0.2.2, the guest's gateway.

## Secrets

A VM's `secrets` map names to host files, such as sops secrets. The guest
reads each as `/run/credstore/<name>`, read-only and root's, so a service there
takes one with `LoadCredential=<name>`; `vms/synergyds.nix` passes its extra
command line this way. They're read when the VM starts, so a changed secret
needs `vm restart <name>`.

## Snapshots

A VM with `data.snapshots = true` is snapshotted hourly: 48 hourly, 14 daily,
4 weekly and 3 monthly are kept. While it runs, autosave pauses around each
snapshot; while it's off, a dataset that hasn't changed isn't snapshotted.

```console
$ doas zfs list -t snapshot -o name,creation data/mc/<name>
$ ls /media/data/mc/servers/<name>/.zfs/snapshot/<snapshot>/   # one file back
$ vm stop <name>
$ doas zfs rollback -r data/mc/<name>@<snapshot>                # everything back
```

`rollback -r` destroys the snapshots taken after the one it returns to.

## Updating a modpack

Stop the server, snapshot it, then update as yourself:

```console
$ vm stop <name>
$ doas zfs snapshot data/mc/<name>@before-update
$ mrpack-install update --server-dir /media/data/mc/servers/<name>
$ vm start <name>
```

`update` keeps backups of files you changed; diff them against the new ones.

## Removing a server

```console
$ vm stop <name>
```

Delete its `vms/<name>.nix` and the import, then deploy as in step 2. The
data stays until you remove it:

```console
$ doas zfs destroy -r <dataset>
```

## When something is wrong

- `vm start` failing with a list of commands is the preflight: run them.
- The server itself failing (no `start.sh`, unaccepted EULA, a crash) is in
  `vm logs <name>`.
- The host side of a VM is units `vm-<name>`, `vm-<name>-preflight`,
  `-share`, `-fs-data`, `-fs-secrets` (with secrets) and `-net`;
  `systemctl status` shows each.
