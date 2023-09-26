# mkosi-kernel

This repository hosts mkosi configuration files intended for kernel development
using mkosi. By default, a fedora rawhide cpio is built which is booted with
qemu's direct kernel boot.

To get started, write the distribution you want to build to mkosi.conf in the
root of the repository in the Distribution section. Currently Fedora and Debian
are supported. For example, for fedora, write the following:

```conf
[Distribution]
Distribution=fedora
```

Then, to build the image and boot it, run the following:

```sh
$ mkosi -f qemu
```

To exit qemu, press `ctrl+a` followed by `c` to enter the qemu monitor, and then
type `quit` to exit the VM.

To build your own kernel, add the following to `mkosi.conf`:

```conf
[Content]
BuildSources=<path-to-your-kernel-sources>:kernel
```

Now run `mkosi -f qemu` again and a custom kernel will be built and booted
instead of the default one. The kconfig file will be picked up from the kernel
source tree at `mkosi.kernel.config`. If it does not exist and the `$CONFIG`
environment variable (set using `Environment=`) is not set, the default config
file shipped with this repository (`mkosi.kernel.config`) is used instead.
Alternatively, `--config` (or `-c`) can be used to pass the config path to use
via the command line (e.g. `mkosi -f build -c <path-to-config>`).

To build the selftests, set `SELFTESTS=1` using `Environment=`.
`SELFTESTS_SKIP_TARGETS=` can be used to skip specific selftests targets, such
as bpf which can take a long time to rebuild.

This configuration will download the required tools to build and boot the image
on the fly. To use this configuration, the following tools have to be installed:

- python 3.9 (Run mkosi with `$MKOSI_INTERPRETER` to point it at an alternative
  interpreter)
- bubblewrap
- package manager of the distribution you're building
- coreutils
