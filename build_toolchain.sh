#!/usr/bin/bash

BINUTILS_VER=2.39
GCC_VER=12.2.0
KERNEL_VER=5.15.65
GLIBC_VER=2.36

TARGET_ARCH=arm-linux-gnueabihf
PREFIX=/opt/cross2
CORES=12

_TERM="---------------------------"
echo $_TERM

echo "TARGET ARCH: $TARGET_ARCH"
echo "BINUTILS: $BINUTILS_VER"
echo "GCC: $GCC_VER"
echo "GLIBC: $GLIBC_VER"
echo "KERNEL: $KERNEL_VER"
echo "NUMBER OF THREADS FOR COMPILATION: $CORES"
echo $_TERM
echo "Will be installed in $PREFIX"
echo $_TERM

export PATH=$PREFIX/bin:$PATH

LOGS_DIR=$PWD/logs
if [ -d $LOGS_DIR ]; then
    rm -r $LOGS_DIR
fi
mkdir $LOGS_DIR

check(){
    if [ ! $? -eq 0 ]; then
	echo "Build failed. See $LOGS_DIR/build.log"
	exit 1
    fi
}

#BINUTILS
echo $_TERM

if [ ! -f binutils-$BINUTILS_VER.tar.bz2 ]; then
    echo "Downloading binutils v$BINUTILS_VER"
    curl -O http://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VER.tar.bz2
    check
fi

echo "Unpacking binutils sources"
tar xvjf binutils-$BINUTILS_VER.tar.bz2 2> $LOGS_DIR/build.log > /dev/null
check

cd binutils-$BINUTILS_VER
echo "Configuring binutils"
./configure --prefix=$PREFIX --target=$TARGET_ARCH --disable-multilib 2> $LOGS_DIR/build.log > /dev/null
check

echo "Building binutils"
make -j$CORES 2> $LOGS_DIR/build.log > /dev/null
check

echo "Installing binutils"
make install 2> $LOGS_DIR/build.log > /dev/null
check 
cd ..
echo $_TERM


#GCC STAGE1

if [ ! -f gcc-$GCC_VER.tar.xz ]; then
    echo "Downloading GCC v$GCC_VER"
    curl -O http://ftp.gnu.org/gnu/gcc/gcc-$GCC_VER/gcc-$GCC_VER.tar.xz
    check
fi

echo "Unpacking GCC sources"
unxz gcc-$GCC_VER.tar.xz
tar xvf gcc-$GCC_VER.tar  2> $LOGS_DIR/build.log > /dev/null
check

mkdir build-gcc
cd build-gcc
echo "Preparing GCC STAGE1"
../gcc-$GCC_VER//configure --prefix=$PREFIX --target=$TARGET_ARCH --disable-multilib --enable-languages=c,c++  2> $LOGS_DIR/build.log > /dev/null
check
echo "Building GCC stage 1"
make -j$CORES all-gcc  2> $LOGS_DIR/build.log > /dev/null
check
echo "Installing GCC stage 1"
make install-gcc  2> $LOGS_DIR/build.log > /dev/null
check
cd ..
echo $_TERM

#Kernel headers
if [ ! -f linux-$KERNEL_VER.tar ]; then
    echo "Downloading kernel tarball"
    curl -O https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$KERNEL_VER.tar.xz
    check
    unxz linux-$KERNEL_VER.tar.xz  2> $LOGS_DIR/build.log > /dev/null
    check
fi
echo "Unpacking kernel sources"
tar xvf linux-$KERNEL_VER.tar  2> $LOGS_DIR/build.log > /dev/null
check
echo "Installing kernel headers in $PREFIX/$TARGET_ARCH"
cd linux-$KERNEL_VER
ARCH=arm make INSTALL_HDR_PATH=$PREFIX/$TARGET_ARCH headers_install  2> $LOGS_DIR/build.log > /dev/null
check
cd ..
echo $_TERM

#GLIBC
if [ ! -f glibc-$GLIBC_VER.tar ]; then
    echo "Downloading GLIBC"
    curl -O http://ftp.gnu.org/gnu/glibc/glibc-$GLIBC_VER.tar.xz
    check
    unxz glibc-$GLIBC_VER.tar.xz 2> $LOGS_DIR/build.log > /dev/null
    check
fi
echo "Unpacking glibc sources"
tar xvf glibc-$GLIBC_VER.tar 2> $LOGS_DIR/build.log > /dev/null
check

mkdir build-glibc
cd build-glibc

echo "Configuring glibc"
../glibc-$GLIBC_VER/configure --prefix=$PREFIX/$TARGET_ARCH --build=$MACHTYPE --host=$TARGET_ARCH --with-headers=$PREFIX/$TARGET_ARCH/include --disable-multilib libc_cv_forced_unwind=yes 2> $LOGS_DIR/build.log > /dev/null
check

echo "Building glibc"
make install-bootstrap-headers=yes install-headers 2> $LOGS_DIR/build.log > /dev/null
check

make -j$CORES csu/subdir_lib 2> $LOGS_DIR/build.log > /dev/null
check

echo "Installing libc.so"
install csu/crt1.o csu/crti.o csu/crtn.o $PREFIX/$TARGET_ARCH/lib 2> $LOGS_DIR/build.log > /dev/null
$TARGET_ARCH-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $PREFIX/$TARGET_ARCH/lib/libc.so 2> $LOGS_DIR/build.log > /dev/null
check
cd ..
echo $_TERM

#GCC stage 2
echo "Building GCC stage 2"
cd build-gcc
make -j$CORES all-target-libgcc 2> $LOGS_DIR/build.log > /dev/null
check
make install-target-libgcc 2> $LOGS_DIR/build.log > /dev/null
check
cd ..

#C Standard lib
echo "Building C standard lib"
cd build-glibc 
make -j$CORES 2> $LOGS_DIR/build.log > /dev/null
check
echo "Installing C standard lib" 
make install 2> $LOGS_DIR/build.log > /dev/null
check
cd ..

#Build C++ standard library
cd build-gcc
echo "Building C++ standard lib"
make -j$CORES 2> $LOGS_DIR/build.log > /dev/null
check
echo "Installing C++ standard lib"
make install 2> $LOGS_DIR/build.log > /dev/null
check
cd ..

echo "Toolchain was successfully built. Have fun!"
