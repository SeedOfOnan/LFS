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

# 8.4. Iana-Etc-20240912
# wget https://github.com/Mic92/iana-etc/releases/download/20240912/iana-etc-20240912.tar.gz
tar -xf iana-etc-20240912.tar.gz
cd iana-etc-20240912
cp -v services protocols /etc
cd ..
rm -r iana-etc-20240912

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
make check
