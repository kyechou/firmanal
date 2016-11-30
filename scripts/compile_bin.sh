#!/bin/sh

if [[ ${USER} != "root" ]]; then
	echo "Please run this script with root privilege."
	exit 1
fi

if [ -e ../configure.sh ]; then
	source ../configure.sh
elif [ -e ./configure.sh ]; then
	source ./configure.sh
else
	echo "Error: Could not find 'configure.sh'!"
	exit 1
fi

# Compile for the binaries

## build the toolchain
git clone http://github.com/GregorR/musl-cross.git
cd musl-cross
sed -i -e 's/http:\/\/ftp\.gnu\.org\/gnu\/binutils\/binutils-2\.25\.1\.tar\.bz2/http:\/\/ftp\.gnu\.org\/gnu\/binutils\/binutils-2\.27\.tar\.bz2/' -e 's/GDB_VERSION=7\.9\.1/GDB_VERSION=7\.11\.1/' -e 's/GMP_VERSION=4\.3\.2/GMP_VERSION=6\.0\.0a/' -e 's/MPC_VERSION=0\.8\.1/MPC_VERSION=1\.0\.2/' -e 's/MPFR_VERSION=2\.4\.2/MPFR_VERSION=3\.1\.3/' -e 's/LANG_CXX=yes/LANG_CXX=no/' ./defs.sh
echo "CFLAGS=\"-fPIC\"" >> ./config.sh
### little-endian MIPS
echo "TRIPLE=mipsel-linux-musl" >> ./config.sh
sed -i -e 's/^LINUX_HEADERS_URL=[[:alnum:][:punct:]]*/LINUX_HEADERS_URL=https:\/\/kernel\.org\/pub\/linux\/kernel\/v2\.6\/longterm\/v2\.6\.32\/linux-2\.6\.32\.70\.tar\.xz/' ./defs.sh
./clean.sh
./build.sh
### big-endian MIPS
sed -i -e 's/^TRIPLE=[[:alpha:]-]*/TRIPLE=mipseb-linux-musl/' ./config.sh
sed -i -e 's/^LINUX_HEADERS_URL=[[:alnum:][:punct:]]*/LINUX_HEADERS_URL=https:\/\/kernel\.org\/pub\/linux\/kernel\/v2\.6\/longterm\/v2\.6\.32\/linux-2\.6\.32\.70\.tar\.xz/' ./defs.sh
./clean.sh
./build.sh
### little-endian ARM
sed -i -e 's/^TRIPLE=[[:alpha:]-]*/TRIPLE=arm-linux-musleabi/' ./config.sh
echo "GCC_BOOTSTRAP_CONFFLAGS=\"--with-arch=armv6 --with-float=softfp\"
GCC_CONFFLAGS=\"--with-arch=armv6 --with-float=softfp\"" >> ./config.sh
sed -i -e 's/^LINUX_HEADERS_URL=[[:alnum:][:punct:]]*/LINUX_HEADERS_URL=https:\/\/kernel\.org\/pub\/linux\/kernel\/v4\.x\/linux-4\.1\.17\.tar\.xz/' ./defs.sh
./clean.sh
./build.sh
cd ..
rm -rf musl-cross/

[[ ! -e ${BINARY_DIR} ]] && mkdir -p ${BINARY_DIR}

## build the console
git clone https://github.com/firmadyne/console.git && cd console
make clean && CC=/opt/cross/arm-linux-musleabi/bin/arm-linux-musleabi-gcc make && mv console ${BINARY_DIR}/console.armel
make clean && CC=/opt/cross/mipseb-linux-musl/bin/mipseb-linux-musl-gcc make && mv console ${BINARY_DIR}/console.mipseb
make clean && CC=/opt/cross/mipsel-linux-musl/bin/mipsel-linux-musl-gcc make && mv console ${BINARY_DIR}/console.mipsel
cd .. && rm -rf console

## build the libnvram
git clone https://github.com/firmadyne/libnvram.git && cd libnvram
make clean && CC=/opt/cross/arm-linux-musleabi/bin/arm-linux-musleabi-gcc make && mv libnvram.so ${BINARY_DIR}/libnvram.so.armel
make clean && CC=/opt/cross/mipseb-linux-musl/bin/mipseb-linux-musl-gcc make && mv libnvram.so ${BINARY_DIR}/libnvram.so.mipseb
make clean && CC=/opt/cross/mipsel-linux-musl/bin/mipsel-linux-musl-gcc make && mv libnvram.so ${BINARY_DIR}/libnvram.so.mipsel
cd .. & rm -rf libnvram

## build the kernel
### little-endian ARM
git clone https://github.com/firmadyne/kernel-v4.1.git && cd kernel-v4.1
mkdir -p build/armel
cp config.armel build/armel/.config
make ARCH=arm CROSS_COMPILE=/opt/cross/arm-linux-musleabi/bin/arm-linux-musleabi- O=./build/armel zImage -j8
cp build/armel/arch/arm/boot/zImage ${BINARY_DIR}/zImage.armel
cd ..
rm -rf kernel-v4.1/
### big-endian MIPS
git clone https://github.com/firmadyne/kernel-v2.6.32.git && cd kernel-v2.6.32
sed -i -e 's/\(^[[:blank:]]if (!\)defined(@val)) {/\1@val) {/' kernel/timeconst.pl
mkdir -p build/mipseb
cp config.mipseb build/mipseb/.config
make ARCH=mips CROSS_COMPILE=/opt/cross/mipseb-linux-musl/bin/mipseb-linux-musl- O=./build/mipseb -j8
cp build/mipseb/vmlinux ${BINARY_DIR}/vmlinux.mipseb
### little-endian MIPS
mkdir -p build/mipsel
cp config.mipsel build/mipsel/.config
make ARCH=mips CROSS_COMPILE=/opt/cross/mipsel-linux-musl/bin/mipsel-linux-musl- O=./build/mipsel -j8
cp build/mipsel/vmlinux ${BINARY_DIR}/vmlinux.mipsel
cd ..
rm -rf kernel-v2.6.32/
