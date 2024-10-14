#!/bin/bash
set -e
set -o pipefail
set -u
set -x
cd gcc-14.2.0/build

make install

# This removes the cross compiler, moved here from 8.85. Cleaning Up
# I think the make install already changes the link /usr/bin/cc
# and overwrites some of the cross compiler, so no turning back
find /usr -depth -name $LFS_TGT\* | xargs rm -rf

# Also moved here from 8.85. Cleaning Up
find /usr/lib /usr/libexec -name \*.la -delete

chown -v -R root:root \
    /usr/lib/gcc/$(gcc -dumpmachine)/14.2.0/include{,-fixed}
ln -svr /usr/bin/cpp /usr/lib
ln -sv gcc.1 /usr/share/man/man1/cc.1
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/14.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/
mkdir -v test
cd test
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
#EXPECT [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log
#EXPECT  /usr/lib/gcc/x86_64-pc-linux-gnu/14.2.0/../../../../lib/Scrt1.o succeeded
#EXPECT  /usr/lib/gcc/x86_64-pc-linux-gnu/14.2.0/../../../../lib/crti.o succeeded
#EXPECT  /usr/lib/gcc/x86_64-pc-linux-gnu/14.2.0/../../../../lib/crtn.o succeeded
grep -B4 '^ /usr/include' dummy.log
#EXPECT  #include <...> search starts here:
 #EXPECT  /usr/lib/gcc/x86_64-pc-linux-gnu/14.2.0/include
 #EXPECT  /usr/local/include
 #EXPECT  /usr/lib/gcc/x86_64-pc-linux-gnu/14.2.0/include-fixed
 #EXPECT  /usr/include
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
#EXPECT  SEARCH_DIR("/usr/x86_64-pc-linux-gnu/lib64")
#EXPECT  SEARCH_DIR("/usr/local/lib64")
#EXPECT  SEARCH_DIR("/lib64")
#EXPECT  SEARCH_DIR("/usr/lib64")
#EXPECT  SEARCH_DIR("/usr/x86_64-pc-linux-gnu/lib")
#EXPECT  SEARCH_DIR("/usr/local/lib")
#EXPECT  SEARCH_DIR("/lib")
#EXPECT  SEARCH_DIR("/usr/lib");
grep "/lib.*/libc.so.6 " dummy.log
#EXPECT attempt to open /usr/lib/libc.so.6 succeeded
grep found dummy.log
#EXPECT found ld-linux-x86-64.so.2 at /usr/lib/ld-linux-x86-64.so.2
rm -v dummy.c a.out dummy.log
cd ..
rmdir -v test
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
cd ../..
rm -r gcc-14.2.0

# 8.30. Ncurses-6.5
tar -xf ncurses-6.5.tar.gz
cd ncurses-6.5
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --with-pkg-config-libdir=/usr/lib/pkgconfig
make
make DESTDIR=$PWD/dest install
install -vm755 dest/usr/lib/libncursesw.so.6.5 /usr/lib
rm -v  dest/usr/lib/libncursesw.so.6.5
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i dest/usr/include/curses.h
cp -av dest/* /
for lib in ncurses form panel menu ; do
    ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
done
ln -sfv libncursesw.so /usr/lib/libcurses.so
cp -v -R doc -T /usr/share/doc/ncurses-6.5
cd ..
rm -r ncurses-6.5

# 8.31. Sed-4.9
tar -xf sed-4.9.tar.xz
cd sed-4.9
./configure --prefix=/usr
make
make html
chown -R tester .
su tester -c "PATH=$PATH make check"
make install
install -d -m755           /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9
cd ..
rm -r sed-4.9

# 8.32. Psmisc-23.7
# wget https://sourceforge.net/projects/psmisc/files/psmisc/psmisc-23.7.tar.xz
tar -xf psmisc-23.7.tar.xz
cd psmisc-23.7
./configure --prefix=/usr
make
make check
make install
cd ..
rm -r psmisc-23.7

# 8.33. Gettext-0.22.5
tar -xf gettext-0.22.5.tar.xz
cd gettext-0.22.5
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.22.5
make
make check
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so
cd ..
rm -r gettext-0.22.5

# 8.34. Bison-3.8.2
tar -xf bison-3.8.2.tar.xz
cd bison-3.8.2
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
make
make check
make install
cd ..
rm -r bison-3.8.2

# 8.35. Grep-3.11
tar -xf grep-3.11.tar.xz
cd grep-3.11
sed -i "s/echo/#echo/" src/egrep.sh
./configure --prefix=/usr
make
make check
make install
cd ..
rm -r grep-3.11

# 8.36. Bash-5.2.37
tar -xf bash-5.2.37.tar.gz
cd bash-5.2.37
./configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            bash_cv_strtold_broken=no \
            --docdir=/usr/share/doc/bash-5.2.37
make
chown -R tester .
