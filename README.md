# mkosi-kernel

This repository hosts mkosi configuration files intended for kernel development
using mkosi. By default, a fedora rawhide cpio is built which is booted with
qemu's direct kernel boot.

To build the default image and boot it:

```sh
$ mkosi -f qemu
```

To build your own kernel create a file `mkosi.conf.d/local.conf` with the
following contents:

```conf
[Content]
BuildSources=<path-to-your-kernel-sources>:kernel
```

Now run `mkosi -f qemu` again and a custom kernel will be built and booted
instead of the default one. The kconfig file will be picked up from the kernel
source tree at `mkosi.kernel.config`. If it does not exist and the `$CONFIG`
environment variable (set using `Environment=`) is not set, the default config
file shipped with this repository (`mkosi.kernel.config`) is used instead.

To build the selftests, set `SELFTESTS=1` using `Environment=`.
`SELFTESTS_SKIP_TARGETS=` can be used to skip specific selftests targets, such
as bpf which can take a long time to rebuild.

This configuration will download the required tools to build and boot the image
on the fly. To use this configuration, the following tools have to be installed:

- python 3.9 (Run mkosi with `$MKOSI_INTERPRETER` to point it at an alternative
  interpreter)
- bubblewrap
- dnf
- coreutils
