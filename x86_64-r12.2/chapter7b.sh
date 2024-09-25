#!/bin/bash
set -e
set -o pipefail
set -u
set -x

touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

# 7.7. Gettext-0.22.5
# wget https://ftp.gnu.org/gnu/gettext/gettext-0.22.5.tar.xz
tar -xf gettext-0.22.5.tar.xz
cd gettext-0.22.5
./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
cd ..
rm -r gettext-0.22.5

# 7.8. Bison-3.8.2
# wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz
tar -xf bison-3.8.2.tar.xz
cd bison-3.8.2
./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2
make
make install
cd ..
rm -r bison-3.8.2

# 7.9. Perl-5.40.0
# wget https://www.cpan.org/src/5.0/perl-5.40.0.tar.xz
tar -xf perl-5.40.0.tar.xz
cd perl-5.40.0
sh Configure -des                                         \
             -D prefix=/usr                               \
             -D vendorprefix=/usr                         \
             -D useshrplib                                \
             -D privlib=/usr/lib/perl5/5.40/core_perl     \
             -D archlib=/usr/lib/perl5/5.40/core_perl     \
             -D sitelib=/usr/lib/perl5/5.40/site_perl     \
             -D sitearch=/usr/lib/perl5/5.40/site_perl    \
             -D vendorlib=/usr/lib/perl5/5.40/vendor_perl \
             -D vendorarch=/usr/lib/perl5/5.40/vendor_perl
make
make install
cd ..
rm -r perl-5.40.0

# 7.10. Python-3.12.5
# wget https://www.python.org/ftp/python/3.12.5/Python-3.12.5.tar.xz
tar -xf Python-3.12.5.tar.xz
cd Python-3.12.5
./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip
make
make install
cd ..
rm -r Python-3.12.5

# 7.11. Texinfo-7.1
# wget https://ftp.gnu.org/gnu/texinfo/texinfo-7.1.tar.xz
tar -xf texinfo-7.1.tar.xz
cd texinfo-7.1
./configure --prefix=/usr
make
make install
cd ..
rm -r texinfo-7.1

# 7.12. Util-linux-2.40.2
# wget https://www.kernel.org/pub/linux/utils/util-linux/v2.40/util-linux-2.40.2.tar.xz
tar -xf util-linux-2.40.2.tar.xz
cd util-linux-2.40.2
mkdir -pv /var/lib/hwclock
./configure --libdir=/usr/lib     \
            --runstatedir=/run    \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-static      \
            --disable-liblastlog2 \
            --without-python      \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.40.2
make
make install
cd ..
rm -r util-linux-2.40.2
