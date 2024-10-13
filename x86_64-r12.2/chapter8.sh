#!/bin/bash
set -e
set -o pipefail
set -u
set -x

# 8.3. Man-pages-6.9.1
# wget https://www.kernel.org/pub/linux/docs/man-pages/man-pages-6.9.1.tar.xz
tar -xf man-pages-6.9.1.tar.xz
cd man-pages-6.9.1
rm -v man3/crypt*
make prefix=/usr install
cd ..
rm -r man-pages-6.9.1

# 8.4. Iana-Etc-20240806
# wget https://github.com/Mic92/iana-etc/releases/download/20240806/iana-etc-20240806.tar.gz
tar -xf iana-etc-20240806.tar.gz
cd iana-etc-20240806
cp -v services protocols /etc
cd ..
rm -r iana-etc-20240806

# 8.5. Glibc-2.40
# wget https://www.iana.org/time-zones/repository/releases/tzdata2024a.tar.gz
tar -xf glibc-2.40.tar.xz
cd glibc-2.40
# First, fix an issue building Glibc with parallel jobs and make-4.4 or later:
sed '/MAKEFLAGS :=/s/)r/) -r/' -i Makerules

patch -Np1 -i ../glibc-2.40-fhs-1.patch
mkdir -v build
cd       build
echo "rootsbindir=/usr/sbin" > configparms
../configure --prefix=/usr                            \
             --disable-werror                         \
             --enable-kernel=4.19                     \
             --enable-stack-protector=strong          \
             --disable-nscd                           \
             libc_cv_slibdir=/usr/lib
make
set +x
make check
set -x
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd

localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
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
#localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
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
tar -xf zlib-1.3.1.tar.xz
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
# Before 8.17.1 Installation of Expect: Verify that the PTYs are working
python3 -c 'from pty import spawn; spawn(["echo", "ok"])'
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
tar -xf pkgconf-2.3.0.tar.gz
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
set -x
make -k check
set +x
grep '^FAIL:' $(find -name '*.log')
make tooldir=/usr install
rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a
cd ../..
rm -r binutils-2.43.1

# 8.21. GMP-6.3.0
tar -xf gmp-6.3.0.tar.xz
cd gmp-6.3.0
#Note if CFLAGS defined and not target 64:
#  ABI=32 ./configure ...
#Note if target less capable than build machine, append the following to configure:
#            --host=none-linux-gnu
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0
make
make html
make check 2>&1 | tee gmp-check-log
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log
#Should report at least "199"
make install
make install-html
cd ..
rm -r gmp-6.3.0

# 8.22. MPFR-4.2.1
tar -xf mpfr-4.2.1.tar.xz
cd mpfr-4.2.1
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.1
make
make html
make check
make install
make install-html
cd ..
rm -r mpfr-4.2.1

# 8.23. MPC-1.3.1
tar -xf mpc-1.3.1.tar.gz
cd mpc-1.3.1
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.3.1
make
make html
make check
make install
make install-html
cd ..
rm -r mpc-1.3.1

# 8.24. Attr-2.5.2
# wget https://download.savannah.gnu.org/releases/attr/attr-2.5.2.tar.gz
tar -xf attr-2.5.2.tar.gz
cd attr-2.5.2
./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.2
make
# Tests fail using tmpfs. The tests need to be run on a filesystem that supports extended attributes such as the ext2, ext3, or ext4 filesystems.
#make check
make install
cd ..
rm -r attr-2.5.2

# 8.25. Acl-2.3.2
# wget https://download.savannah.gnu.org/releases/acl/acl-2.3.2.tar.xz
tar -xf acl-2.3.2.tar.xz
cd acl-2.3.2
./configure --prefix=/usr         \
            --disable-static      \
            --docdir=/usr/share/doc/acl-2.3.2
make
make install
cd ..
rm -r acl-2.3.2

# 8.26. Libcap-2.70
# wget https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.70.tar.xz
tar -xf libcap-2.70.tar.xz
cd libcap-2.70
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib
make test
make prefix=/usr lib=lib install
cd ..
rm -r libcap-2.70

# 8.27. Libxcrypt-4.4.36
# wget https://github.com/besser82/libxcrypt/releases/download/v4.4.36/libxcrypt-4.4.36.tar.xz
tar -xf libxcrypt-4.4.36.tar.xz
cd libxcrypt-4.4.36
./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=no     \
            --disable-static             \
            --disable-failure-tokens
make
make check
make install
cd ..
rm -r libxcrypt-4.4.36

# 8.28. Shadow-4.16.0
# wget https://github.com/shadow-maint/shadow/releases/download/4.16.0/shadow-4.16.0.tar.xz
tar -xf shadow-4.16.0.tar.xz
cd shadow-4.16.0
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs
#Note for Cracklib support:
#  sed -i 's:DICTPATH.*:DICTPATH\t/lib/cracklib/pw_dict:' etc/login.defs
touch /usr/bin/passwd
./configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --with-group-name-max-length=32
make
make exec_prefix=/usr install
make -C man install-man

# 8.25.2. Configuring Shadow
#########
# To enable shadowed passwords, run the following command:
#pwconv
# To enable shadowed group passwords, run:
#grpconv

mkdir -pv /etc/default
useradd -D --gid 999

# If you would prefer that these mailbox files are not created by useradd, issue the following command:
sed -i '/MAIL/s/yes/no/' /etc/default/useradd

#passwd root #use blank -- a password of zero length (do it interactively later)
cd ..
rm -r shadow-4.16.0

# 8.29. GCC-14.2.0
tar -xf gcc-14.2.0.tar.xz
cd gcc-14.2.0
sed -e '/m64=/s/lib64/lib/' \
    -i.orig gcc/config/i386/t-linux64 #x86_64
mkdir -v build
cd       build
../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --enable-host-pie        \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib
make
ulimit -s -H unlimited
sed -e '/cpython/d'               -i ../gcc/testsuite/gcc.dg/plugin/plugin.exp
sed -e 's/no-pic /&-no-pie /'     -i ../gcc/testsuite/gcc.target/i386/pr113689-1.c
sed -e 's/300000/(1|300000)/'     -i ../libgomp/testsuite/libgomp.c-c++-common/pr109062.c
sed -e 's/{ target nonpic } //' \
    -e '/GOTPCREL/d'              -i ../gcc/testsuite/gcc.target/i386/fentryname3.c
chown -R tester .
set +x
su tester -c "PATH=$PATH make -k check"
set -x
../contrib/test_summary
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

# 8.36. Bash-5.2.32
tar -xf bash-5.2.32.tar.gz
cd bash-5.2.32
./configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            bash_cv_strtold_broken=no \
            --docdir=/usr/share/doc/bash-5.2.32
make
chown -R tester .
set +x
su -s /usr/bin/expect tester << "EOF"
set timeout -1
spawn make tests
expect eof
lassign [wait] _ _ _ value
exit $value
EOF
set -x

make install
#exec /usr/bin/bash --login #moved 3-lines down
cd ..
rm -r bash-5.2.32

##########################
#Replace the running bash
#Note: can't copy/paste past here
exec /usr/bin/bash --login
##########################

# 8.35. Libtool-2.4.7
# wget https://ftp.gnu.org/gnu/libtool/libtool-2.4.7.tar.xz
tar -xf libtool-2.4.7.tar.xz
cd libtool-2.4.7
./configure --prefix=/usr
make
set +x
make -k check # TESTSUITEFLAGS=-j$(nproc)
set -x
make install
rm -fv /usr/lib/libltdl.a
cd ..
rm -r libtool-2.4.7

# 8.38. GDBM-1.24
# wget https://ftp.gnu.org/gnu/gdbm/gdbm-1.24.tar.gz
tar -xf gdbm-1.24.tar.gz
cd gdbm-1.24
./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat
make
make check
make install
cd ..
rm -r gdbm-1.24

# 8.39. Gperf-3.1
# wget https://ftp.gnu.org/gnu/gperf/gperf-3.1.tar.gz
tar -xf gperf-3.1.tar.gz
cd gperf-3.1
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
make
make -j1 check
make install
cd ..
rm -r gperf-3.1

# 8.40. Expat-2.6.2
# wget https://prdownloads.sourceforge.net/expat/expat-2.6.2.tar.xz
tar -xf expat-2.6.2.tar.xz
cd expat-2.6.2
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.6.2
make
make check
make install
install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.6.2
cd ..
rm -r expat-2.6.2

# 8.41. Inetutils-2.5
# wget https://ftp.gnu.org/gnu/inetutils/inetutils-2.5.tar.xz
tar -xf inetutils-2.5.tar.xz
cd inetutils-2.5
sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c
./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers
make
make check
make install
mv -v /usr/{,s}bin/ifconfig
cd ..
rm -r inetutils-2.5

# 8.42. Less-661
# wget https://www.greenwoodsoftware.com/less/less-661.tar.gz
tar -xf less-661.tar.gz
cd less-661
./configure --prefix=/usr --sysconfdir=/etc
make
make check
make install
cd ..
rm -r less-661

# 8.43. Perl-5.40.0
tar -xf perl-5.40.0.tar.xz
cd perl-5.40.0
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des                                          \
             -D prefix=/usr                                \
             -D vendorprefix=/usr                          \
             -D privlib=/usr/lib/perl5/5.40/core_perl      \
             -D archlib=/usr/lib/perl5/5.40/core_perl      \
             -D sitelib=/usr/lib/perl5/5.40/site_perl      \
             -D sitearch=/usr/lib/perl5/5.40/site_perl     \
             -D vendorlib=/usr/lib/perl5/5.40/vendor_perl  \
             -D vendorarch=/usr/lib/perl5/5.40/vendor_perl \
             -D man1dir=/usr/share/man/man1                \
             -D man3dir=/usr/share/man/man3                \
             -D pager="/usr/bin/less -isR"                 \
             -D useshrplib                                 \
             -D usethreads
make
TEST_JOBS=$(nproc) make test_harness
make install
unset BUILD_ZLIB BUILD_BZIP2
cd ..
rm -r perl-5.40.0

# 8.44. XML::Parser-2.47
# wget https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.47.tar.gz
tar -xf XML-Parser-2.47.tar.gz
cd XML-Parser-2.47
perl Makefile.PL
make
make test
make install
cd ..
rm -r XML-Parser-2.47

# 8.45. Intltool-0.51.0
# wget https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz
tar -xf intltool-0.51.0.tar.gz
cd intltool-0.51.0
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr
make
make check
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
cd ..
rm -r intltool-0.51.0

# 8.46. Autoconf-2.72
# wget https://ftp.gnu.org/gnu/autoconf/autoconf-2.72.tar.xz
tar -xf autoconf-2.72.tar.xz
cd autoconf-2.72
./configure --prefix=/usr
make
make check # TESTSUITEFLAGS=-j$(nproc)
make install
cd ..
rm -r autoconf-2.72

# 8.47. Automake-1.17
# wget https://ftp.gnu.org/gnu/automake/automake-1.17.tar.xz
tar -xf automake-1.17.tar.xz
cd automake-1.17
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.17
make
make -j20 check
make install
cd ..
rm -r automake-1.17

# 8.48. OpenSSL-3.3.1
# wget https://www.openssl.org/source/openssl-3.3.1.tar.gz
tar -xf openssl-3.3.1.tar.gz
cd openssl-3.3.1
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic
make
HARNESS_JOBS=$(nproc) make test
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.3.1
cp -vfr doc/* /usr/share/doc/openssl-3.3.1
cd ..
rm -r openssl-3.3.1

# 8.49. Kmod-33
# wget https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-33.tar.xz
tar -xf kmod-33.tar.xz
cd kmod-33
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --with-openssl    \
            --with-xz         \
            --with-zstd       \
            --with-zlib       \
            --disable-manpages
make
make install

for target in depmod insmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /usr/sbin/$target
  rm -fv /usr/bin/$target
done

cd ..
rm -r kmod-33

# 8.50. Libelf from Elfutils-0.191
# wget https://sourceware.org/ftp/elfutils/0.191/elfutils-0.191.tar.bz2
tar -xf elfutils-0.191.tar.bz2
cd elfutils-0.191
./configure --prefix=/usr                \
            --disable-debuginfod         \
            --enable-libdebuginfod=dummy
make
make check
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm -v /usr/lib/libelf.a
cd ..
rm -r elfutils-0.191

# 8.51. Libffi-3.4.6
# wget https://github.com/libffi/libffi/releases/download/v3.4.6/libffi-3.4.6.tar.gz
tar -xf libffi-3.4.6.tar.gz
cd libffi-3.4.6
#Note: if building for another system, change --with-gcc-arch=<target-architecture>
./configure --prefix=/usr          \
            --disable-static       \
            --with-gcc-arch=native
make
make check
make install
cd ..
rm -r libffi-3.4.6

# 8.52. Python-3.12.5
# wget https://www.python.org/ftp/python/doc/3.12.5/python-3.12.5-docs-html.tar.bz2
tar -xf Python-3.12.5.tar.xz
cd Python-3.12.5
./configure --prefix=/usr        \
            --enable-shared      \
            --with-system-expat  \
            --enable-optimizations
make
make test TESTOPTS="--timeout 120" # Known to hang indefinitly in the partial LFS environment.
make install

#Disable root-user and version check
cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF

install -v -dm755 /usr/share/doc/python-3.12.5/html

tar --no-same-owner \
    -xvf ../python-3.12.5-docs-html.tar.bz2
cp -R --no-preserve=mode python-3.12.5-docs-html/* \
    /usr/share/doc/python-3.12.5/html
cd ..
rm -r Python-3.12.5

# 8.53. Flit-Core-3.9.0
# wget https://pypi.org/packages/source/f/flit-core/flit_core-3.9.0.tar.gz
tar -xf flit_core-3.9.0.tar.xz
cd flit_core-3.9.0
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --no-user --find-links dist flit_core
cd ..
rm -r flit_core-3.9.0

# 8.54. Wheel-0.44.0
# wget https://pypi.org/packages/source/w/wheel/wheel-0.44.0.tar.gz
tar -xf wheel-0.44.0.tar.gz
cd wheel-0.44.0
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links=dist wheel
cd ..
rm -r wheel-0.44.0

# 8.55. Setuptools-72.2.0
# wget https://pypi.org/packages/source/s/setuptools/setuptools-72.2.0.tar.gz
tar -xf setuptools-72.2.0.tar.gz
cd setuptools-72.2.0
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist setuptools
cd ..
rm -f setuptools-72.2.0

# 8.52. Ninja-1.12.1
# wget https://github.com/ninja-build/ninja/archive/v1.12.1/ninja-1.12.1.tar.gz
tar -xf ninja-1.12.1.tar.gz
cd ninja-1.12.1

# Optional support for: export NINJAJOBS=
#sed -i '/int Guess/a \
#  int   j = 0;\
#  char* jobs = getenv( "NINJAJOBS" );\
#  if ( jobs != NULL ) j = atoi( jobs );\
#  if ( j > 0 ) return j;\
#' src/ninja.cc

python3 configure.py --bootstrap
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
cd ..
rm -r ninja-1.12.1

# 8.57. Meson-1.5.1
# wget https://github.com/mesonbuild/meson/releases/download/1.5.1/meson-1.5.1.tar.gz
tar -xf meson-1.5.1.tar.gz
cd meson-1.5.1
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson
cd ..
rm -r meson-1.5.1

# 8.58. Coreutils-9.5
# wget https://www.linuxfromscratch.org/patches/lfs/12.2/coreutils-9.5-i18n-2.patch
tar -xf coreutils-9.5.tar.xz
cd coreutils-9.5
patch -Np1 -i ../coreutils-9.5-i18n-2.patch
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime
make
make NON_ROOT_USERNAME=tester check-root
groupadd -g 102 dummy -U tester
chown -R tester .
su tester -c "PATH=$PATH make -k RUN_EXPENSIVE_TESTS=yes check" \
   < /dev/null
groupdel dummy
make install
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
cd ..
rm -r coreutils-9.5

# 8.59. Check-0.15.2
# wget https://github.com/libcheck/check/releases/download/0.15.2/check-0.15.2.tar.gz
tar -xf check-0.15.2.tar.gz
cd check-0.15.2
./configure --prefix=/usr --disable-static
make
make check #minutes long pause but no errors reported
make docdir=/usr/share/doc/check-0.15.2 install
cd ..
rm -r check-0.15.2

# 8.60. Diffutils-3.10
tar -xf diffutils-3.10.tar.xz
cd diffutils-3.10
./configure --prefix=/usr
make
make check
make install
cd ..
rm -r diffutils-3.10

# 8.61. Gawk-5.3.0
tar -xf gawk-5.3.0.tar.xz
cd gawk-5.3.0
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr
make
chown -R tester .
su tester -c "PATH=$PATH make check"
rm -f /usr/bin/gawk-5.3.0
make install
ln -sv gawk.1 /usr/share/man/man1/awk.1
mkdir -pv                                   /usr/share/doc/gawk-5.3.0
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.3.0
cd ..
rm -r gawk-5.3.0

# 8.62. Findutils-4.10.0
tar -xf findutils-4.10.0.tar.xz
cd findutils-4.10.0
#i?86: TIME_T_32_BIT_OK=yes ./configure --prefix=/usr --localstatedir=/var/lib/locate
./configure --prefix=/usr --localstatedir=/var/lib/locate #x86_64
make
chown -R tester .
su tester -c "PATH=$PATH make check"
make install
cd ..
rm -r findutils-4.10.0

# 8.63. Groff-1.23.0
# wget https://ftp.gnu.org/gnu/groff/groff-1.23.0.tar.gz
tar -xf groff-1.23.0.tar.gz
cd groff-1.23.0
PAGE=letter ./configure --prefix=/usr
make
make check
make install
cd ..
rm -r groff-1.23.0

# 8.64. GRUB-2.12 using https://www.linuxfromscratch.org/blfs/view/svn/postlfs/grub-efi.html but without unifont (requires freetype2)
# wget https://ftp.gnu.org/gnu/grub/grub-2.12.tar.xz
#tar -xf grub-2.12.tar.xz
#cd grub-2.12
#unset {C,CPP,CXX,LD}FLAGS
#echo depends bli part_gpt > grub-core/extra_deps.lst
#./configure --prefix=/usr          \
#            --sysconfdir=/etc      \
#            --disable-efiemu       \
#            --disable-werror
#make
# Most of the tests depend on packages that are not available in the limited LFS environment. To run the tests anyway, run:
#make check
#make install
#mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
#cd ..
#rm -r grub-2.06

# 8.65. Gzip-1.13
tar -xf gzip-1.13.tar.xz
cd gzip-1.13
./configure --prefix=/usr
make
make check
make install
cd ..
rm -r gzip-1.13

# 8.66. IPRoute2-6.10.0
# wget https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-6.10.0.tar.xz
tar -xf iproute2-6.10.0.tar.xz
cd iproute2-6.10.0
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
make NETNS_RUN_DIR=/run/netns
make SBINDIR=/usr/sbin install
mkdir -pv             /usr/share/doc/iproute2-6.10.0
cp -v COPYING README* /usr/share/doc/iproute2-6.10.0
cd ..
rm -r iproute2-6.10.0

# 8.67. Kbd-2.6.4
# wget https://www.kernel.org/pub/linux/utils/kbd/kbd-2.6.4.tar.xz
# wget https://www.linuxfromscratch.org/patches/lfs/12.2/kbd-2.6.4-backspace-1.patch
tar -xf kbd-2.6.4.tar.xz
cd kbd-2.6.4
patch -Np1 -i ../kbd-2.6.4-backspace-1.patch
sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
./configure --prefix=/usr --disable-vlock
make
make check
make install
cp -R -v docs/doc -T /usr/share/doc/kbd-2.6.4
cd ..
rm -r kbd-2.6.4

# 8.68. Libpipeline-1.5.7
# wget https://download.savannah.gnu.org/releases/libpipeline/libpipeline-1.5.7.tar.gz
tar -xf libpipeline-1.5.7.tar.gz
cd libpipeline-1.5.7
./configure --prefix=/usr
make
make check
make install
cd ..
rm -r libpipeline-1.5.7

# 8.69. Make-4.4.1
tar -xf make-4.4.1.tar.gz
cd make-4.4.1
./configure --prefix=/usr
make
chown -R tester .
su tester -c "PATH=$PATH make check"
make install
cd ..
rm -r make-4.4.1

# 8.70. Patch-2.7.6
tar -xf patch-2.7.6.tar.xz
cd patch-2.7.6
./configure --prefix=/usr
make
make check
make install
cd ..
rm -r patch-2.7.6

# 8.71. Tar-1.35
tar -xf tar-1.35.tar.xz
cd tar-1.35
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr
make
make check
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.35
cd ..
rm -r tar-1.35

# 8.72. Texinfo-7.1
tar -xf texinfo-7.1.tar.xz
cd texinfo-7.1
./configure --prefix=/usr
make
make check
make install
#make TEXMF=/usr/share/texmf install-tex
cd ..
rm -r texinfo-7.1

# 8.73. Vim-9.1.0660
# wget https://github.com/vim/vim/archive/v9.1.0660/vim-9.1.0660.tar.gz
tar -xf vim-9.1.0660.tar.gz
cd vim-9.1.0660
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
make
chown -R tester .
su tester -c "TERM=xterm-256color LANG=en_US.UTF-8 make -j1 test" \
   &> vim-test.log
make install
# If you want "vi" to run vim (next 4 lines):
#ln -sv vim /usr/bin/vi
#for L in  /usr/share/man/{,*/}man1/vim.1; do
#    ln -sv vim.1 $(dirname $L)/vi.1
#done
# See also 8.73.2. Configuring Vim
ln -sv ../vim/vim91/doc /usr/share/doc/vim-9.1.0660
cd ..
rm -r vim-9.1.0660

# 8.74. MarkupSafe-2.1.5
# wget https://pypi.org/packages/source/M/MarkupSafe/MarkupSafe-2.1.5.tar.gz
tar -xf MarkupSafe-2.1.5.tar.gz
cd MarkupSafe-2.1.5
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --no-user --find-links dist Markupsafe
cd ..
rm -r MarkupSafe-2.1.5

# 8.75. Jinja2-3.1.4
# wget https://pypi.org/packages/source/J/Jinja2/jinja2-3.1.4.tar.gz
tar -xf jinja2-3.1.4.tar.gz
cd jinja2-3.1.4
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --no-user --find-links dist Jinja2
cd ..
rm -r jinja2-3.1.4

# 8.76. Udev from Systemd-256.4
# wget https://github.com/systemd/systemd/archive/v256.4/systemd-256.4.tar.gz
# wget https://anduin.linuxfromscratch.org/LFS/udev-lfs-20230818.tar.xz
# wget https://anduin.linuxfromscratch.org/LFS/systemd-man-pages-256.4.tar.xz
tar -xf systemd-256.4.tar.gz
cd systemd-256.4
sed -i -e 's/GROUP="render"/GROUP="video"/' \
       -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in
sed '/systemd-sysctl/s/^/#/' -i rules.d/99-systemd.rules.in
sed '/NETWORK_DIRS/s/systemd/udev/' -i src/basic/path-lookup.h
mkdir -p build
cd       build

meson setup ..                  \
      --prefix=/usr             \
      --buildtype=release       \
      -D mode=release           \
      -D dev-kvm-mode=0660      \
      -D link-udev-shared=false \
      -D logind=false           \
      -D vconsole=false
export udev_helpers=$(grep "'name' :" ../src/udev/meson.build | \
                      awk '{print $3}' | tr -d ",'" | grep -v 'udevadm')
ninja udevadm systemd-hwdb                                           \
      $(ninja -n | grep -Eo '(src/(lib)?udev|rules.d|hwdb.d)/[^ ]*') \
      $(realpath libudev.so --relative-to .)                         \
      $udev_helpers
install -vm755 -d {/usr/lib,/etc}/udev/{hwdb.d,rules.d,network}
install -vm755 -d /usr/{lib,share}/pkgconfig
install -vm755 udevadm                             /usr/bin/
install -vm755 systemd-hwdb                        /usr/bin/udev-hwdb
ln      -svfn  ../bin/udevadm                      /usr/sbin/udevd
cp      -av    libudev.so{,*[0-9]}                 /usr/lib/
install -vm644 ../src/libudev/libudev.h            /usr/include/
install -vm644 src/libudev/*.pc                    /usr/lib/pkgconfig/
install -vm644 src/udev/*.pc                       /usr/share/pkgconfig/
install -vm644 ../src/udev/udev.conf               /etc/udev/
install -vm644 rules.d/* ../rules.d/README         /usr/lib/udev/rules.d/
install -vm644 $(find ../rules.d/*.rules \
                      -not -name '*power-switch*') /usr/lib/udev/rules.d/
install -vm644 hwdb.d/*  ../hwdb.d/{*.hwdb,README} /usr/lib/udev/hwdb.d/
install -vm755 $udev_helpers                       /usr/lib/udev
install -vm644 ../network/99-default.link          /usr/lib/udev/network
tar -xvf ../../udev-lfs-20230818.tar.xz
make -f udev-lfs-20230818/Makefile.lfs install
tar -xf ../../systemd-man-pages-256.4.tar.xz                            \
    --no-same-owner --strip-components=1                              \
    -C /usr/share/man --wildcards '*/udev*' '*/libudev*'              \
                                  '*/systemd.link.5'                  \
                                  '*/systemd-'{hwdb,udevd.service}.8

sed 's|systemd/network|udev/network|'                                 \
    /usr/share/man/man5/systemd.link.5                                \
  > /usr/share/man/man5/udev.link.5

sed 's/systemd\(\\\?-\)/udev\1/' /usr/share/man/man8/systemd-hwdb.8   \
                               > /usr/share/man/man8/udev-hwdb.8

sed 's|lib.*udevd|sbin/udevd|'                                        \
    /usr/share/man/man8/systemd-udevd.service.8                       \
  > /usr/share/man/man8/udevd.8

rm /usr/share/man/man*/systemd*
unset udev_helpers
udev-hwdb update
cd ..
rm -r systemd-256.4

# 8.77. Man-DB-2.12.1
# wget https://download.savannah.gnu.org/releases/man-db/man-db-2.12.1.tar.xz
tar -xf man-db-2.12.1.tar.xz
cd man-db-2.12.1
./configure --prefix=/usr                         \
            --docdir=/usr/share/doc/man-db-2.12.1 \
            --sysconfdir=/etc                     \
            --disable-setuid                      \
            --enable-cache-owner=bin              \
            --with-browser=/usr/bin/lynx          \
            --with-vgrind=/usr/bin/vgrind         \
            --with-grap=/usr/bin/grap             \
            --with-systemdtmpfilesdir=            \
            --with-systemdsystemunitdir=
make
make check
make install
cd ..
rm -r man-db-2.12.1

# 8.78. Procps-ng-4.0.4
# wget https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-4.0.4.tar.xz
tar -xf procps-ng-4.0.4.tar.xz
cd procps-ng-4.0.4
./configure --prefix=/usr                           \
            --docdir=/usr/share/doc/procps-ng-4.0.4 \
            --disable-static                        \
            --disable-kill
make
chown -R tester .
su tester -c "PATH=$PATH make check"
make install
cd ..
rm -r procps-ng-4.0.4

# 8.79. Util-linux-2.40.2
tar -xf util-linux-2.40.2.tar.xz
cd util-linux-2.40.2
./configure --bindir=/usr/bin     \
            --libdir=/usr/lib     \
            --runstatedir=/run    \
            --sbindir=/usr/sbin   \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-liblastlog2 \
            --disable-static      \
            --without-python      \
            --without-systemd     \
            --without-systemdsystemunitdir        \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.40.2
make
# See warning note about testing and the kernel CONFIG_SCSI_DEBUG option
touch /etc/fstab
chown -R tester .
su tester -c "make -k check"
#The hardlink tests will fail if the host's kernel does not have the option CONFIG_CRYPTO_USER_API_HASH enabled
# or does not have any options providing a SHA256 implementation (for example, CONFIG_CRYPTO_SHA256,
# or CONFIG_CRYPTO_SHA256_SSSE3 if the CPU supports Supplemental SSE3) enabled.
make install
cd ..
rm -r util-linux-2.40.2

# 8.80. E2fsprogs-1.47.1
# wget https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v1.47.1/e2fsprogs-1.47.1.tar.gz
tar -xf e2fsprogs-1.47.1.tar.gz
cd e2fsprogs-1.47.1
mkdir -v build
cd       build
../configure --prefix=/usr           \
             --sysconfdir=/etc       \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
make
make check
make install
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
cd ../..
rm -r e2fsprogs-1.47.1

# 8.81. Sysklogd-2.6.1
# wget https://github.com/troglobit/sysklogd/releases/download/v2.6.1/sysklogd-2.6.1.tar.gz
tar -xf sysklogd-2.6.1.tar.gz
cd sysklogd-2.6.1
./configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --runstatedir=/run \
            --without-logger
make
make install

# 8.75.2. Configuring Sysklogd
#########
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# Do not open any internet ports.
secure_mode 2

# End /etc/syslog.conf
EOF

cd ..
rm -r sysklogd-2.6.1

# 8.82. Sysvinit-3.10
# wget https://github.com/slicer69/sysvinit/releases/download/3.10/sysvinit-3.10.tar.xz
# wget https://www.linuxfromscratch.org/patches/lfs/12.2/sysvinit-3.10-consolidated-1.patch
tar -xf sysvinit-3.10.tar.xz
cd sysvinit-3.10
patch -Np1 -i ../sysvinit-3.10-consolidated-1.patch
make
make install
cd ..
rm -r sysvinit-3.10
