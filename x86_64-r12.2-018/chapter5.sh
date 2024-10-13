#!/bin/bash
if [ "$(whoami)" != "lfs" ]; then exit 1; fi
if [ -z ${LFS+x} ]; then exit 1; fi
if [ -z ${XCC+x} ]; then exit 1; fi
if [ -z ${LFS_TGT+x} ]; then exit 1; fi
set -e
set -o pipefail
set -u
set -x

# ====
# 4.2. Creating a limited directory layout in LFS filesystem
# ====
mkdir -v $LFS/{etc,usr,var,$XCC} $LFS/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

cd $LFS/sources

# 5.2. Binutils-2.43.1 - Pass 1
# wget https://sourceware.org/pub/binutils/releases/binutils-2.43.1.tar.xz
tar -xf binutils-2.43.1.tar.xz
cd binutils-2.43.1
mkdir -v build
cd       build
../configure --prefix=$LFS/$XCC  \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-new-dtags  \
             --enable-default-hash-style=gnu  \
	     --disable-static    \
	     --enable-64-bit-bfd \
	     --disable-multilib
make
make install-strip
cd ../..
rm -rf binutils-2.43.1

# 5.3. GCC-14.2.0 - Pass 1
# wget https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.xz
# wget https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.1.tar.xz
# wget https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz
# wget https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz
tar -xf gcc-14.2.0.tar.xz
cd gcc-14.2.0

tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc

sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 #x86_64

mkdir -v build
cd       build

../configure                  \
    --target=$LFS_TGT         \
    --prefix=$LFS/$XCC        \
    --with-glibc-version=2.40 \
    --with-sysroot=$LFS       \
    --with-newlib             \
    --without-headers         \
    --enable-default-pie      \
    --enable-default-ssp      \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++

make all-gcc all-target-libgcc #was: make
make install-strip-gcc install-strip-target-libgcc #was: make install

cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h

cd ..
rm -rf gcc-14.2.0

# 5.4. Linux-6.11.1 API Headers
# wget https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.11.1.tar.xz
tar -xf linux-6.11.1.tar.xz
cd linux-6.11.1

make mrproper

make ARCH=x86 INSTALL_HDR_PATH=$LFS/usr headers_install

cd ..
rm -r linux-6.11.1

# 5.5. Glibc-2.40
# wget https://ftp.gnu.org/gnu/glibc/glibc-2.40.tar.xz
# wget https://www.linuxfromscratch.org/patches/lfs/development/glibc-2.40-fhs-1.patch
tar -xf glibc-2.40.tar.xz
cd glibc-2.40

# For LSB compliance
#ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3 #i?86
mkdir -v $LFS/lib64 #x86_64
ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64 #x86_64
ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3 #x86_64

# Fix an issue building Glibc with parallel jobs and make-4.4 or later:
sed '/MAKEFLAGS :=/s/)r/) -r/' -i Makerules

patch -Np1 -i ../glibc-2.40-fhs-1.patch

mkdir -v build
cd       build

echo "rootsbindir=/usr/sbin" > configparms

../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=4.19               \
      --with-headers=$LFS/usr/include    \
      --disable-nscd                     \
      libc_cv_slibdir=/usr/lib

make
make DESTDIR=$LFS install
sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

echo 'int main(){}' | $LFS_TGT-gcc -xc -
$LFS_TGT-readelf -l a.out | grep "\[Requesting program interpreter: /lib64/ld-linux-x86-64\.so\.2\]"
rm -v a.out

cd ../..
rm -rf glibc-2.40

# 5.6. Libstdc++ from GCC-14.2.0
tar -xf gcc-14.2.0.tar.xz
cd gcc-14.2.0

mkdir -v build
cd       build

../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/$XCC/$LFS_TGT/include/c++/14.2.0

make
make DESTDIR=$LFS install-strip
rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la

cd ../..
rm -rf gcc-14.2.0
