# LOS

Lechi's Operating System

## Limine

This project uses the Limine bootloader, version 12.9.0. To upgrade to the
latest version, follow these steps:

1. Download the latest release tarball from [here][limine-releases].
1. Run `./configure --prefix="$PWD/build" --enable-uefi-x86-64 CC=clang`.
1. Run `make install` and copy the required files from the `build` directory.

[limine-releases]: https://github.com/Limine-Bootloader/Limine/releases
