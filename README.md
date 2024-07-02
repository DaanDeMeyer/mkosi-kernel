# mkosi-kernel

This repository hosts mkosi configuration files intended for kernel development
using mkosi. By default, a an image is built which is booted with qemu's direct
kernel boot and VirtioFS.

To get started, write the distribution you want to build to `mkosi.local.conf`
in the root of the repository in the Distribution section. Currently CentOS,
Fedora and Debian are supported. For example, for fedora, write the following:

```conf
[Distribution]
Distribution=fedora
```

Then, to build the image and boot it, run the following:

```sh
$ mkosi -f qemu
```

To exit qemu, press `ctrl+a` followed by `c` to enter the qemu monitor, and then
type `quit` to exit the VM. Alternatively, run `systemctl poweroff`.

To build your own kernel, add the following to `mkosi.conf`:

```conf
[Config]
@Include=modules/kernel

[Content]
BuildSources=<path-to-your-kernel-sources>:kernel
```

If you want to mount a directory into the qemu VM, you can add the following:

```conf
[Host]
RuntimeTrees=<path-to-sources>:/path/in/guest
```

Now run `mkosi -f qemu` again and a custom kernel will be built and booted
instead of the default one. The kconfig file will be picked up from the kernel
source tree at `mkosi.kernel.config`. If it does not exist and the `$CONFIG`
environment variable (set using `Environment=`) is not set, the default config
file shipped with this repository (`mkosi.kernel.config`) is used instead.
Alternatively, `--config` (or `-c`) can be used to pass the config path to use
via the command line (e.g. `mkosi -f build -c <path-to-config>`).

To build the selftests, set `SELFTESTS=1` using `Environment=`.
`SELFTESTS_TARGETS=` can be used to only build specific selftests targets.
`SELFTESTS_SKIP_TARGETS=` can be used to skip specific selftests targets, such
as bpf which can take a long time to rebuild.

For each kernel, the out-of-tree build subdirectory used is synthesized from
the localversion files in the given kernel source tree and the
`CONFIG_LOCALVERSION` setting in the configuration and the `$LOCALVERSION`
environment variable.

Various other modules are supported as well. For example, to use the btrfs-progs
module to bulid and install btrfs-progs:

```conf
[Config]
@Include=modules/btrfs-progs

[Content]
BuildSources=<path-to-your-btrfs-progs-sources>:btrfs-progs
```

The same applies to the other modules (`fstests`, `ltp`, `blktests`,
`bpfilter`).

To enable multiple modules, you can do the following:

```conf
[Config]
@Include=modules/btrfs-progs
         modules/kernel

[Content]
BuildSources=<path-to-your-btrfs-progs-sources>:btrfs-progs
             <path-to-your-kernel-sources>:kernel
```

To temporarily disable building a specific module, you can simply comment out
the relevant `BuildSources=` entry without disabling the module itself.

## Requirements

This configuration will download the required tools to build and boot the image
on the fly. To use this configuration, the following tools have to be installed:

- mkosi v20
- python 3.9 (Set `$MKOSI_INTERPRETER` to point to an alternative interpreter)
- bubblewrap
- package manager of the distribution you're building
- coreutils
- util-linux

## Contributing

All package and kconfig lists must be sorted using `sort -u`.
