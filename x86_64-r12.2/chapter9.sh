#!/bin/bash
set -e
set -o pipefail
set -u
set -x

# 9.2. LFS-Bootscripts-20240825
# wget https://www.linuxfromscratch.org/lfs/downloads/development/lfs-bootscripts-20240825.tar.xz
tar -xvf lfs-bootscripts-20240825.tar.xz
cd lfs-bootscripts-20240825
make install
cd ..
rm -r lfs-bootscripts-20240825

#######
# 9.4.1.2. Creating Custom Udev Rules (ie naming scheme)
#######
#TODO: in 9.5.1 below, replace "eth0" with the name of your ehernet device. Or follow this part of LFS.
#TODO: in 9.5.2 and 9.5.3 below, replace "whozawhatzit" with your computer (host) name
#	and "8.8.8.8"/"8.8.4.4" with the IP address of your primary/secondary nameserver.

#######
# 9.5. General Network Configuration
#######

#########
# 9.5.1. Creating Network Interface Configuration Files
#########
cat > /etc/sysconfig/ifconfig.eth0 << "EOF"
ONBOOT=yes
IFACE=eth0
SERVICE=ipv4-static
IP=192.168.1.2
GATEWAY=192.168.1.1
PREFIX=24
BROADCAST=192.168.1.255
EOF

#########
# 9.5.2. Creating the /etc/resolv.conf File
#########
cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf

domain localdomain
nameserver 8.8.8.8
nameserver 8.8.4.4

# End /etc/resolv.conf
EOF

#########
# 9.5.3. Configuring the system hostname
#########
echo "whozawhatzit" > /etc/hostname

#########
# 9.5.4. Customizing the /etc/hosts File
#########
cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost.localdomain localhost
127.0.1.1 whozawhatzit.localdomain whozawhatzit
192.168.1.2 whozawhatzit.localdomain whozawhatzit
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

# End /etc/hosts
EOF

#######
# 9.6. System V Bootscript Usage and Configuration
#######

#########
# 9.6.2. Configuring Sysvinit
#########
cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S06:once:/sbin/sulogin
s1:1:respawn:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600

# End /etc/inittab
EOF

#########
# 9.6.4. Configuring the System Clock
#########
cat > /etc/sysconfig/clock << "EOF"
# Begin /etc/sysconfig/clock

UTC=1

# Set this to any options you might need to give to hwclock,
# such as machine hardware clock type for Alphas.
CLOCKPARAMS=

# End /etc/sysconfig/clock
EOF

#########
# 9.6.5. Configuring the Linux Console
#########
cat > /etc/sysconfig/console << "EOF"
# Begin /etc/sysconfig/console

UNICODE="1"
#KEYMAP="??"
FONT="lat1-16 -m 8859-1"

# End /etc/sysconfig/console
EOF

#######
# 9.7. Configuring the System Locale
#######
LC_ALL=en_US.ISO-8859-1 locale language
LC_ALL=en_US.ISO-8859-1 locale charmap
LC_ALL=en_US.ISO-8859-1 locale int_curr_symbol
LC_ALL=en_US.ISO-8859-1 locale int_prefix

cat > /etc/profile << "EOF"
# Begin /etc/profile

if [[ "$TERM" = linux ]]; then
  export LANG=C.UTF-8
else
  export LANG=LC_ALL=en_US.ISO-8859-1
fi

# End /etc/profile
EOF

#######
# 9.8. Creating the /etc/inputrc File
#######
cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8-bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF

#######
# 9.9. Creating the /etc/shells File
#######
cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF

##
# Chapter 10. Making the LFS System Bootable
##

#######
# 10.2. Creating the /etc/fstab File
########
cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point    type     options             dump  fsck
#                                                                order

/dev/sdc2      /              ext4     defaults            1     1
#/dev/<yyy>    swap           swap     pri=1               0     0
proc           /proc          proc     nosuid,noexec,nodev 0     0
sysfs          /sys           sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts       devpts   gid=5,mode=620      0     0
tmpfs          /run           tmpfs    defaults            0     0
devtmpfs       /dev           devtmpfs mode=0755,nosuid    0     0
tmpfs          /dev/shm       tmpfs    nosuid,nodev        0     0
cgroup2        /sys/fs/cgroup cgroup2  nosuid,noexec,nodev 0     0

# End /etc/fstab
EOF

