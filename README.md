Buildroot for MilkV Duo board
=============================

This Buildroot generates all components from scratch, including the RiscV cross-compiler, for the MilkV Duo board.

###  Getting the sources

    $ git clone https://github.com/kinsamanka/milkv-buildroot.git
    
Alternatively :

    $ curl -L https://github.com/kinsamanka/milkv-buildroot/archive/refs/heads/main.tar.gz | \
           tar xvzf -
    $ mv milkv-buildroot-main milkv-buildroot

### Prerequisites

On Ubuntu, the following command will install the needed packages:

    $ sudo apt-get install bc bison build-essential flex libssl-dev unzip

For Fedora/CentOS/RHEL OS:

    $ sudo yum install -y autoconf automake bc bison bzip2 cpio file flex gcc gcc-c++ openssl-devel \
                          ncurses-devel patchutils perl-core rsync tar unzip wget which
                          
### Build

This step will build the cross-compiler and then build the sd card image.

    $ make O=$(pwd)/build -C milkv-buildroot milkv_duo_defconfig
    $ cd build
    $ make

If the build is successful, the ```images``` folder will contain the following files:

    milkv-duo_sdcard.img.gz
    milkv-duo_sdcard.img
    
### Save the cross-compiler

To save time on the next builds, it is best to save the generated cross-compiler.
The following command will gather and compress the required files.

    $ make sdk

The resulting packaged cross-compiler: ```images/riscv64-buildroot-linux-musl_sdk-buildroot.tar.gz```

Transfer this file to the root of the Buildroot directory:

    $ mv images/riscv64-buildroot-linux-musl_sdk-buildroot.tar.gz ../milkv-buildroot

### Build using the packaged cross-compiler

    $ make O=$(pwd)/build -C milkv-buildroot milkv_duo_external_toolchain_defconfig
    $ cd build
    $ make

### Notes

The behavior of the MilkV Duo board is set by the ```/etc/milkv-duo.conf``` file.

- To disable the blinking LED, set ```ENABLE_BLINK``` to ```0```
- To use the usb port as host, set ```USB_MODE``` to ```host```
