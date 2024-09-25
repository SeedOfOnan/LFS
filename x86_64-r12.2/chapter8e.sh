#!/bin/bash
set -e
set -o pipefail
set -u
set -x
#cd bash-5.2.32

#su -s /usr/bin/expect tester << "EOF"
#set timeout -1
#spawn make tests
#expect eof
#lassign [wait] _ _ _ value
#exit $value
#EOF

#make install
##exec /usr/bin/bash --login #moved 3-lines down
#cd ..
#rm -r bash-5.2.32

##########################
#Replace the running bash
#Note: can't copy/paste past here
#exec /usr/bin/bash --login
##########################

# 8.35. Libtool-2.4.7
# wget https://ftp.gnu.org/gnu/libtool/libtool-2.4.7.tar.xz
tar -xf libtool-2.4.7.tar.xz
cd libtool-2.4.7
./configure --prefix=/usr
make
make -k check # TESTSUITEFLAGS=-j$(nproc)
