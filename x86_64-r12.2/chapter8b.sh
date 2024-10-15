#!/bin/bash
set -e
set -o pipefail
set -u
set -x
cd glibc-2.40/build

touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd

localedef -i C -f UTF-8 C.UTF-8
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f ISO-8859-1 en_GB
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_ES -f ISO-8859-15 es_ES@euro
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i is_IS -f ISO-8859-1 is_IS
localedef -i is_IS -f UTF-8 is_IS.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f ISO-8859-15 it_IT@euro
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i se_NO -f UTF-8 se_NO.UTF-8
localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
localedef -i zh_TW -f UTF-8 zh_TW.UTF-8

# Alternatively, install all locales listed in the glibc-2.40/localedata/SUPPORTED file
#make localedata/install-locales

# The following two locales are needed for some tests later in this chapter:
#localedef -i C -f UTF-8 C.UTF-8
#localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true

# 8.5.2. Configuring Glibc

# 8.5.2.1. Adding nsswitch.conf
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

# 8.5.2.2. Adding time zone data
tar -xf ../../tzdata2024a.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/Denver
unset ZONEINFO

ln -sfv /usr/share/zoneinfo/America/Denver /etc/localtime

# 8.5.2.3. Configuring the Dynamic Loader
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d

cd ../..
rm -r glibc-2.40

# 8.6. Zlib-1.3.1
# wget https://zlib.net/fossils/zlib-1.3.1.tar.gz
tar -xf zlib-1.3.1.tar.gz
cd zlib-1.3.1
./configure --prefix=/usr
make
make check
make install
rm -fv /usr/lib/libz.a
cd ..
rm -r zlib-1.3.1

# 8.7. Bzip2-1.0.8
# wget https://www.sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz
# wget https://www.linuxfromscratch.org/patches/lfs/12.2/bzip2-1.0.8-install_docs-1.patch
tar -xf bzip2-1.0.8.tar.gz
cd bzip2-1.0.8
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install
cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done
rm -fv /usr/lib/libbz2.a
cd ..
rm -r bzip2-1.0.8

# 8.8. Xz-5.6.2
# wget https://github.com/tukaani-project/xz/releases/download/v5.6.2/xz-5.6.2.tar.xz
tar -xf xz-5.6.2.tar.xz
cd xz-5.6.2
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.6.2
make
make check
make install
cd ..
rm -r xz-5.6.2

# 8.9. Lz4-1.10.0
# wget https://github.com/lz4/lz4/releases/download/v1.10.0/lz4-1.10.0.tar.gz
tar -xf lz4-1.10.0.tar.gz
cd lz4-1.10.0
make BUILD_STATIC=no PREFIX=/usr
make -j1 check
make BUILD_STATIC=no PREFIX=/usr install
cd ..
rm -r lz4-1.10.0

# 8.10. Zstd-1.5.6
# wget https://github.com/facebook/zstd/releases/download/v1.5.6/zstd-1.5.6.tar.gz
tar -xf zstd-1.5.6.tar.gz
cd zstd-1.5.6
make prefix=/usr
make check
make prefix=/usr install
rm -v /usr/lib/libzstd.a
cd ..
rm -r zstd-1.5.6

# 8.11. File-5.45
tar -xf file-5.45.tar.gz
cd file-5.45
./configure --prefix=/usr
make
make check
make install
cd ..
rm -r file-5.45

# 8.12. Readline-8.2.13
# wget https://ftp.gnu.org/gnu/readline/readline-8.2.13.tar.gz
tar -xf readline-8.2.13.tar.gz
cd readline-8.2.13
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf
./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.2.13
make SHLIB_LIBS="-lncursesw"
make SHLIB_LIBS="-lncursesw" install
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.2.13
cd ..
rm -r readline-8.2.13

# 8.13. M4-1.4.19
tar -xf m4-1.4.19.tar.xz
cd m4-1.4.19
./configure --prefix=/usr
make
make check
make install
cd ..
rm -r m4-1.4.19

# 8.14. Bc-6.7.6
# wget https://github.com/gavinhoward/bc/releases/download/6.7.6/bc-6.7.6.tar.xz
tar -xf bc-6.7.6.tar.xz
cd bc-6.7.6
CC=gcc ./configure --prefix=/usr -G -O3 -r
make
make test
make install
cd ..
rm -r bc-6.7.6

# 8.15. Flex-2.6.4
# wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
tar -xf flex-2.6.4.tar.gz
cd flex-2.6.4
./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static
make
make check
make install
ln -sv flex   /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1
cd ..
rm -r flex-2.6.4

# 8.16. Tcl-8.6.14
# wget https://downloads.sourceforge.net/tcl/tcl8.6.14-src.tar.gz
# wget https://downloads.sourceforge.net/tcl/tcl8.6.14-html.tar.gz
tar -xf tcl8.6.14-src.tar.gz
cd tcl8.6.14
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --disable-rpath
make

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.7|/usr/lib/tdbc1.1.7|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.7/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.7/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.7|/usr/include|"            \
    -i pkgs/tdbc1.1.7/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.4|/usr/lib/itcl4.2.4|" \
    -e "s|$SRCDIR/pkgs/itcl4.2.4/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.2.4|/usr/include|"            \
    -i pkgs/itcl4.2.4/itclConfig.sh

unset SRCDIR
make test
make install
chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers
ln -sfv tclsh8.6 /usr/bin/tclsh
mv -v /usr/share/man/man3/{Thread,Tcl_Thread}.3
cd ..
tar -xf ../tcl8.6.14-html.tar.gz --strip-components=1
mkdir -v -p /usr/share/doc/tcl-8.6.14
cp -v -r  ./html/* /usr/share/doc/tcl-8.6.14
cd ..
rm -r tcl8.6.14

# 8.17. Expect-5.45.4
# wget https://prdownloads.sourceforge.net/expect/expect5.45.4.tar.gz
# wget https://www.linuxfromscratch.org/patches/lfs/12.2/expect-5.45.4-gcc14-1.patch
tar -xf expect5.45.4.tar.gz
cd expect5.45.4
patch -Np1 -i ../expect-5.45.4-gcc14-1.patch
./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --disable-rpath         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include
make
make test
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
cd ..
rm -r expect5.45.4

# 8.18. DejaGNU-1.6.3
# wget https://ftp.gnu.org/gnu/dejagnu/dejagnu-1.6.3.tar.gz
tar -xf dejagnu-1.6.3.tar.gz
cd dejagnu-1.6.3
mkdir -v build
cd       build
../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi
make check
make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3
cd ../..
rm -r dejagnu-1.6.3

# 8.19. Pkgconf-2.3.0
# wget https://distfiles.ariadne.space/pkgconf/pkgconf-2.3.0.tar.xz
tar -xf pkgconf-2.3.0.tar.xz
cd pkgconf-2.3.0
./configure --prefix=/usr              \
            --disable-static           \
            --docdir=/usr/share/doc/pkgconf-2.3.0
make
make install
ln -sv pkgconf   /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1
cd ..
rm -r pkgconf-2.3.0

# 8.20. Binutils-2.43.1
tar -xf binutils-2.43.1.tar.xz
cd binutils-2.43.1
mkdir -v build
cd       build
../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --enable-new-dtags  \
             --with-system-zlib  \
             --enable-default-hash-style=gnu
make tooldir=/usr
make -k check
