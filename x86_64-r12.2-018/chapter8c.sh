#!/bin/bash
set -e
set -o pipefail
set -u
set -x
cd binutils-2.43.1/build

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
su tester -c "PATH=$PATH make -k check"
