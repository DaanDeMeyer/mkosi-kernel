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
Include=modules/kernel

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
Include=modules/btrfs-progs

[Content]
BuildSources=<path-to-your-btrfs-progs-sources>:btrfs-progs
```

The same applies to the other modules (`fstests`, `ltp`, `blktests`,
`bpfilter`).

To enable multiple modules, you can do the following:

```conf
[Config]
Include=modules/btrfs-progs
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

- mkosi v24 (development version from git)
- python 3.9 (Set `$MKOSI_INTERPRETER` to point to an alternative interpreter)
- bubblewrap
- package manager of the distribution you're building
- coreutils
- util-linux

## Incremental builds

To avoid having to rebuild the image for every change made to a module,
mkosi-kernel supports incremental builds that allows for rebuilding projects
and making the changes available in the image without rebuilding the image
itself. Using this mode requires mkosi version `24~devel` or newer.

To make use of this, we'll need to make sure the source and build directories
of each module are mounted into the virtual machine by adding the following to
our mkosi.local.conf:

```conf
[Host]
RuntimeBuildSources=yes
```

Next, build and boot the image with `mkosi -f qemu`. In the virtual machine, the
sources of each enabled module can be accessed at `/work/src` and the build
directory of each module can be accessed at `/work/build`. Additionally, the
kernel modules are automatically bind mounted from `/work/build/kernel/modules`
to `/usr/lib/modules` if that directory is available.

To rebuild each module without rebuilding the image, open another terminal on
the host and run `mkosi -t none build -i`. This will rebuild each enabled
module. To select which modules to rebuild, simply pass the name of the module
as an option. For example, run `mkosi -t none build -i --btrfs-progs` to only
rebuild the btrfs-progs module. After the command finishes, the changes will be
available in `/work/build` in the virtual machine.

Note that for the kernel module, only modules are rebuilt, so this approach does
not work if the corresponding code in the kernel cannot be compiled as a module.

To reload a kernel module after doing a incremental build, run `rmmod <module>`
followed by `modprobe <module>`. Of course you need to make sure the module is
not currently being used to be able to remove it. For example, if you're
building a disk image and hacking on a filesystem (e.g. `btrfs`), you have to
make sure the rootfs is not on `btrfs` to be able to unload the `btrfs` module
with `rmmod`. You can override the filesystem used by `systemd-repart` when
mkosi builds a disk image by creating a directory `mkosi.repart` in the
mkosi-kernel repository and writing a file `00-root.conf` in there with the
following contents:

```conf
[Partition]
Type=root
Format=<filesystem>
CopyFiles=/
SizeMinBytes=8G
SizeMaxBytes=8G
```

## Kernel debugging with gdb

With a few configuration changes, the kernel booted in an mkosi-kernel VM
can be debugged with gdb. On the mkosi side, this config option is needed
in order to have qemu listen for gdb, by default on localhost tcp port 1234:
```conf
[Host]
QemuArgs=-s
```

Mkosi-kernel does the kernel build in a chroot directory, and places the
vmlinux file in one of its own directories, too. We need to tell gdb
where all the files are, in order for things to work properly.

```
$ gdb
(gdb) file ~/source/mkosi-kernel/mkosi.builddir/<distro-release-arch>/kernel/image.vmlinux
(gdb) set substitute-path /work/src/kernel ~/source/linux
(gdb) target remote localhost:1234
```

Now things are ready to investigate what is happening with the kernel.
The gdb commands you will want to start with are probably figuring out what
each CPU is doing, and then getting a backtrace from each CPU:

```
(gdb) info threads
(gdb) thread 1
(gdb) bt
```

Repeat for each interesting looking CPU, and then dig into the details
as needed.

## Contributing

All package and kconfig lists must be sorted using `sort -u`.
