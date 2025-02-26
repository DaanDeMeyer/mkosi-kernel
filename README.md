# mkosi-kernel

This repository hosts mkosi configuration files intended for kernel development
using mkosi. By default, a an image is built which is booted with qemu's direct
kernel boot and VirtioFS.

To get started, write the distribution you want to build to `mkosi.local.conf`
in the root of the repository in the Distribution section. Currently CentOS,
Fedora and Debian are supported. For example, for fedora, write the following:

```ini
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

```ini
[Config]
Profiles=kernel

[Build]
BuildSources=<path-to-your-kernel-sources>:kernel
```

If you want to mount a directory into the qemu VM, you can add the following:

```ini
[Runtime]
RuntimeTrees=<path-to-sources>:/path/in/guest
```

Now run `mkosi -f qemu` again and a custom kernel will be built and booted
instead of the default one. The kconfig file will be picked up from the kernel
source tree at `mkosi.kernel.config`. If it does not exist and the `$CONFIG`
environment variable (set using `Environment=`) is not set, the default config
file shipped with this repository (`mkosi.kernel.config`) is used instead.
Alternatively, `--config` (or `-c`) can be used to pass the config path to use
via the command line (e.g. `mkosi -f build -- -c <path-to-config>`).

To build the selftests, set `SELFTESTS=1` using `Environment=`.
`SELFTESTS_TARGETS=` can be used to only build specific selftests targets.
`SELFTESTS_SKIP_TARGETS=` can be used to skip specific selftests targets, such
as bpf which can take a long time to rebuild.

For each kernel, the out-of-tree build subdirectory used is synthesized from
the localversion files in the given kernel source tree and the
`CONFIG_LOCALVERSION` setting in the configuration and the `$LOCALVERSION`
environment variable.

Various other profiles are supported as well. For example, to use the btrfs-progs
profile to build and install btrfs-progs:

```ini
[Config]
Profiles=btrfs-progs

[Build]
BuildSources=<path-to-your-btrfs-progs-sources>:btrfs-progs
```

The same applies to the other profiles (`fstests`, `ltp`, `blktests`,
`bpfilter`).

To enable multiple profiles, you can do the following:

```ini
[Config]
Profiles=btrfs-progs,kernel

[Build]
BuildSources=<path-to-your-btrfs-progs-sources>:btrfs-progs
             <path-to-your-kernel-sources>:kernel
```

To temporarily disable building a specific profile, you can simply comment out
the relevant `BuildSources=` entry without disabling the profile itself.

## Requirements

This configuration will download the required tools to build and boot the image
on the fly. To use this configuration, the following tools have to be installed:

- mkosi v25
- python 3.9 (Set `$MKOSI_INTERPRETER` to point to an alternative interpreter)
- package manager of the distribution you're building
- coreutils
- util-linux

## Incremental builds

To avoid having to rebuild the image for every change made to a profile,
mkosi-kernel supports incremental builds that allows for rebuilding projects
and making the changes available in the image without rebuilding the image
itself. Using this mode requires mkosi version `26~devel` or newer.

To make use of this, we'll need to make sure the source and build directories
of each profile are mounted into the virtual machine by adding the following to
our mkosi.local.conf:

```ini
[Runtime]
RuntimeBuildSources=yes
```

Next, build and boot the image with `mkosi -f qemu`. In the virtual machine, the
sources of each enabled profile can be accessed at `/work/src` and the build
directory of each profile can be accessed at `/work/build`. Additionally, the
kernel modules are automatically bind mounted from `/work/build/kernel/modules`
to `/usr/lib/modules` if that directory is available.

To rebuild each profile without rebuilding the image, open another terminal on
the host and run `mkosi -R build -- -i`. This will rebuild each enabled
profile. After the command finishes, the changes will be available in `/work/build`
in the virtual machine. To select which profiles to rebuild, simply pass the name
of the profile as an option. For example, run `mkosi -R build -- -i --kernel`
to only rebuild the kernel profile.

To reload a kernel module after doing a incremental kernel build, run `rmmod <module>`
followed by `modprobe <module>`. Of course you need to make sure the module is
not currently being used to be able to remove it. When using the disk image
output, the filesystem used can be overridden by adding the following to
`mkosi.local.conf`:

```ini
[Build]
Environment=SYSTEMD_REPART_OVERRIDE_FSTYPE_ROOT=ext4
```

To summarize, with incremental mode, the following workflow becomes possible
to hack on the kernel:

```sh
mkosi -f qemu                 # Build image and boot into a virtual machine
                              # Switch to another terminal on the host
mkosi -R -- -i -k             # Rebuild the kernel without rebuilding the image
                              # Switch back to the virtual machine
rmmod btrfs && modprobe btrfs # Reload the btrfs module
...
systemctl poweroff            # Shutdown the virtual machine
mkosi -R -- -i -k             # Rebuild the kernel without rebuilding the image
mkosi qemu                    # Boot virtual machine again with new kernel
```

Note that this workflow depends on a stable kernel version. If the kernel version
changes, you will have to rebuild the full image once with `mkosi -f` before
continuing to use this workflow.

## Kernel debugging with gdb

With a few configuration changes, the kernel booted in an mkosi-kernel VM
can be debugged with gdb. On the mkosi side, this config option is needed
in order to have qemu listen for gdb, by default on localhost tcp port 1234:

```ini
[Runtime]
QemuArgs=-s
```

Mkosi-kernel does the kernel build in a chroot directory, and places the
vmlinux file in one of its own directories, too. We need to tell gdb
where all the files are, in order for things to work properly.

```
$ gdb
(gdb) file ~/source/mkosi-kernel/mkosi.builddir/<distro-release-arch>/kernel/<localversion>/image.vmlinux
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

## Building with latest kernel and latest systemd

To build mkosi-kernel with the latest systemd straight from git, first
we need to build systemd rpms from the source repository:

```sh
git clone https://github.com/systemd/systemd
mkosi -t none -f
ls mkosi.builddir/<distribution>~<release>~<arch>
```

Then we have to configure mkosi-kernel to pick up the rpms we just built
(make sure the mkosi distribution and release for mkosi-kernel are the same as
the mkosi distribution and release in the systemd repository):

```ini
# mkosi.local.conf

[Config]
Profiles=kernel
PackageDirectories=<path-to-systemd-checkout>/build/mkosi.builddir/<distribution>~<release>~<arch>

[Build]
BuildSources=.
             <path-to-kernel-checkout>:kernel
```

Finally, build and boot the mkosi-kernel image to get an image with the latest
kernel and the latest systemd:

```sh
mkosi -f qemu
```

## Language Server Protocol (clangd)

**mkosi-kernel** provides a script that can be used to run clangd on the kernel
sources to provide code completion and diagnostics to editors that support the
Language Server Protocol. To make use of this, point your editor's LSP plugin
to the `mkosi.clangd` script inside this repository and pass the name of the
profile on which you want to run clangd as the first argument. For example, for
vscode, the configuration to run clangd on the kernel would look as follows:

```json
{
    "clangd.path": "/home/daandemeyer/projects/mkosi-kernel/mkosi.clangd",
    "clangd.arguments": ["kernel"],
}
```

Note that the script requires an up-to-date cache of the mkosi-kernel image build,
so if it fails to start you likely have to run `mkosi -f` once in the mkosi-kernel
directory to make sure the caches are up-to-date.

## Contributing

All package and kconfig lists must be sorted using `sort -u`.
