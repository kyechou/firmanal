#!/bin/bash
set -e


if [[ ${USER} == "root" ]]; then
	echo "Please run this script without root privilege."
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

## postgresql setup
sudo pacman -S --needed --noconfirm postgresql
echo "Setting the password for system user 'postgres'..."
sudo passwd postgres
sudo -u postgres initdb --locale $LANG -E UTF-8 -D '/var/lib/postgres/data'
sudo systemctl enable postgresql.service
sudo systemctl start postgresql.service
sudo -u postgres createuser firmadyne -s
sudo -u postgres createdb -O firmadyne -U firmadyne firmware
sudo -u postgres psql -d firmware < ${DB_DIR}/schema

## install dependencies
sudo pacman -S --needed --noconfirm bc fakeroot curl git openbsd-netcat nmap net-snmp util-linux fuse binwalk python-crypto python-capstone squashfs-tools python-magic python-psycopg2 qemu qemu-arch-extra mtd-utils tar unrar xz gzip bzip2 p7zip arj lhasa cabextract arj cpio python-opengl sleuthkit

yaourt -S --needed --noconfirm busybox-static multipath-tools jefferson-git ubi_reader flawfinder

## firmware-mod-kit
git clone https://aur.archlinux.org/firmware-mod-kit.git && cd firmware-mod-kit
sed -i -e "8s/^source=.*$/source=('https:\/\/storage.googleapis.com\/google-code-archive-downloads\/v2\/code.google.com\/firmware-mod-kit\/fmk_099.tar.gz')/" PKGBUILD
updpkgsums
makepkg -srci --noconfirm --needed
cd .. && rm -rf firmware-mod-kit

## uml_utilities
curl -L -O http://user-mode-linux.sourceforge.net/uml_utilities_20070815.tar.bz2
tar jxf uml_utilities_20070815.tar.bz2
rm uml_utilities_20070815.tar.bz2
cd tools-20070815/
make
sudo make install
cd ..
rm -rf tools-20070815/

## sasquatch
git clone https://aur.archlinux.org/sasquatch.git && cd sasquatch
sed -i -e "/^makedepends=('gcc49')$/d" -e "s/gcc-4\.9/gcc/g" PKGBUILD
makepkg -srci --noconfirm --needed
cd .. && rm -rf sasquatch/

## yaffshiv
git clone https://github.com/devttys0/yaffshiv.git && cd yaffshiv
sudo python setup.py install
cd .. && sudo rm -rf yaffshiv

## unstuff
mkdir stuffit && cd stuffit
wget -O - http://my.smithmicro.com/downloads/files/stuffit520.611linux-i386.tar.gz | tar -xz
sudo cp bin/unstuff /usr/bin/unstuff
cd .. && rm -rf stuffit

## snowman (decompiler)
sudo pacman -S --noconfirm --needed gcc cmake boost qt5-base
git clone https://github.com/nihilus/snowman.git && cd snowman
mkdir build && cd build
BOOST_ROOT=/usr/include/boost
mkdir qt
ln -s /usr/include/qt qt/include
ln -s /usr/lib/qt qt/lib
QTDIR=$(pwd)/qt
cmake -D CMAKE_BUILD_TYPE=Release -D IDA_PLUGIN_ENABLED=NO -D NC_QT5=YES -D CMAKE_INSTALL_PREFIX=/usr/local ../src
cmake --build .
sudo cmake --build . --target install
unlink ${QTDIR}/include
unlink ${QTDIR}/lib
cd ../.. && rm -rf snowman

echo "Finish setup!"
