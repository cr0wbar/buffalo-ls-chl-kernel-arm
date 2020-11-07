## Description
This repo contains a script to build the GNU toolchain for a Marvell Kirkwood 
processor and the config file to build a kernel for a Buffalo LS-CHL-V2 NAS.
After the toolchain is built, add its `bin` directory to the `PATH` env variable

### Build the toolchain
Run `chmod +x build_toolchain.sh` and then `./build_toolchain.sh`. 
This will download all the tools and binaries. It has been tested on Arch Linux.

### Build the kernel
Checkout the linux source code (last version tested is the [4.9.x branch](https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.19.155.tar.xz))
and run `make nconfig`. Import the `crowbar.config` configuration.
Run `make modules` then `make`.
From the kernel source root

```
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- zImage modules
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- kirkwood-lschlv2.dtb
cat arch/arm/boot/zImage arch/arm/boot/dts/kirkwood-lschlv2.dtb > arch/arm/boot/zImage_w_dtb
mkimage -A arm -O linux -T kernel -C none -a 0x00008000 -e 0x00008000 -n 'MyCustomLinuxKernel' -d arch/arm/boot/zImage_w_dtb arch/arm/boot/uImage
```


Now for the modules, to install in a target directory "$MODULES_DIR"
```
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- INSTALL_MOD_PATH=$MODULES_DIR  modules_install
```

Go to [Archlinux ARM](https://archlinuxarm.org/) and grab yourself the latest distribution for Marvel Kirkwood processors.
package the modules with the distro and replace the kernel in the /boot directory.

MAKE A BACKUP OF EVERYTHING ON YOUR NAS, this procedure is likely to brick it.
