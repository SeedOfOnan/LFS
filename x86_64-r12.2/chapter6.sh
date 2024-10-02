#!/bin/bash
if [ "$(whoami)" != "lfs" ]; then exit 1; fi
if [ -z ${LFS+x} ]; then exit 1; fi
if [ -z ${XCC+x} ]; then exit 1; fi
if [ -z ${LFS_TGT+x} ]; then exit 1; fi
set -e
set -o pipefail
set -u
set -x

cd $LFS/sources

# 6.2. M4-1.4.19
# wget https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz
tar -xf m4-1.4.19.tar.xz
cd m4-1.4.19
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install-strip
cd ..
rm -rf m4-1.4.19

# 6.3. Ncurses-6.5
# wget https://ftp.gnu.org/gnu/ncurses/ncurses-6.5.tar.gz
#or: wget https://invisible-mirror.net/archives/ncurses/ncurses-6.5.tar.gz
tar -xf ncurses-6.5.tar.gz
cd ncurses-6.5
sed -i s/mawk// configure
mkdir build
pushd build
  ../configure
  make -C include
  make -C progs tic
popd
./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada
make
#NOTE: install[-strip] requires $LFS/$XCC/$LFS_TGT/bin in PATH before alternate 'strip'
make DESTDIR=$LFS PATH=$LFS/$XCC/$LFS_TGT/bin:$PATH TIC_PATH=$(pwd)/build/progs/tic install
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h
cd ..
rm -r ncurses-6.5

# 6.4. Bash-5.2.32
# wget https://ftp.gnu.org/gnu/bash/bash-5.2.32.tar.gz
tar -xf bash-5.2.32.tar.gz
cd bash-5.2.32
./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc              \
            bash_cv_strtold_broken=no
make
#NOTE: install-strip requires $LFS/$XCC/$LFS_TGT/bin in PATH before alternate 'strip'
make DESTDIR=$LFS PATH=$LFS/$XCC/$LFS_TGT/bin:$PATH install-strip
ln -sv bash $LFS/bin/sh
cd ..
rm -rf bash-5.2.32

# 6.5. Coreutils-9.5
# wget https://ftp.gnu.org/gnu/coreutils/coreutils-9.5.tar.xz
tar -xf coreutils-9.5.tar.xz
cd coreutils-9.5
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime
make
make DESTDIR=$LFS install-strip
mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8
cd ..
rm -rf coreutils-9.5

# 6.6. Diffutils-3.10
# wget https://ftp.gnu.org/gnu/diffutils/diffutils-3.10.tar.xz
tar -xf diffutils-3.10.tar.xz
cd diffutils-3.10
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install-strip
cd ..
rm -rf diffutils-3.10

# 6.7. File-5.45
# wget https://astron.com/pub/file/file-5.45.tar.gz
tar -xf file-5.45.tar.gz
cd file-5.45
mkdir build
pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
popd
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install-strip
rm -v $LFS/usr/lib/libmagic.la
cd ..
rm -r file-5.45

# 6.8. Findutils-4.10.0
# wget https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz
tar -xf findutils-4.10.0.tar.xz
cd findutils-4.10.0
./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install-strip
cd ..
rm -r findutils-4.10.0

# 6.9. Gawk-5.3.0
# wget https://ftp.gnu.org/gnu/gawk/gawk-5.3.0.tar.xz
tar -xf gawk-5.3.0.tar.xz
cd gawk-5.3.0
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install-strip
cd ..
rm -r gawk-5.3.0

# 6.10. Grep-3.11
# wget https://ftp.gnu.org/gnu/grep/grep-3.11.tar.xz
tar -xf grep-3.11.tar.xz
cd grep-3.11
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install-strip
cd ..
rm -rf grep-3.11

# 6.11. Gzip-1.13
# wget https://ftp.gnu.org/gnu/gzip/gzip-1.13.tar.xz
tar -xf gzip-1.13.tar.xz
cd gzip-1.13
./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install-strip
cd ..
rm -rf gzip-1.13

# 6.12. Make-4.4.1
# wget https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz
tar -xf make-4.4.1.tar.gz
cd make-4.4.1
./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install-strip
cd ..
rm -rf make-4.4.1

# 6.13. Patch-2.7.6
# wget https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz
tar -xf patch-2.7.6.tar.xz
cd patch-2.7.6
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install-strip
cd ..
rm -r patch-2.7.6

# 6.14. Sed-4.9
# wget https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz
tar -xf sed-4.9.tar.xz
cd sed-4.9
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install-strip
cd ..
rm -rf sed-4.9

# 6.15. Tar-1.35
# wget https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz
tar -xf tar-1.35.tar.xz
cd tar-1.35
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install-strip
cd ..
rm -r tar-1.35

# 6.16. Xz-5.6.2
# wget https://github.com/tukaani-project/xz/releases/download/v5.6.2/xz-5.6.2.tar.xz
tar -xf xz-5.6.2.tar.xz
cd xz-5.6.2
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.6.2
make
make DESTDIR=$LFS install-strip
rm -v $LFS/usr/lib/liblzma.la
cd ..
rm -r xz-5.6.2

# 6.17. Binutils-2.43.1 - Pass 2
tar -xf binutils-2.43.1.tar.xz
cd binutils-2.43.1
sed '6009s/$add_dir//' -i ltmain.sh
mkdir -v build
cd       build
../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-new-dtags         \
    --enable-default-hash-style=gnu
make
make DESTDIR=$LFS install-strip
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
cd ../..
rm -rf binutils-2.43.1

# 6.18. GCC-14.2.0 - Pass 2
tar -xf gcc-14.2.0.tar.xz
cd gcc-14.2.0
tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc
sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 #x86_64

#Allow building libgcc and libstdc++ libraries with POSIX threads support
sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir -v build
cd       build

../configure                                       \
    --build=$(../config.guess)                     \
    --host=$LFS_TGT                                \
    --target=$LFS_TGT                              \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
    --prefix=/usr                                  \
    --with-build-sysroot=$LFS                      \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libvtv                               \
    --enable-languages=c,c++
make
make DESTDIR=$LFS install-strip
ln -sv gcc $LFS/usr/bin/cc
cd ../..
rm -rf gcc-14.2.0
