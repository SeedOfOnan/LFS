#!/bin/bash
set -e
set -o pipefail
set -u
set -x
cd libtool-2.4.7

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
tar -xf flit_core-3.9.0.tar.gz
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
rm -r setuptools-72.2.0

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
#rm -r grub-2.12

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
# wget https://www.linuxfromscratch.org/patches/lfs/11.2/kbd-2.6.4-backspace-1.patch
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
mv -v vim-test.log ..
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
cd ../..
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
