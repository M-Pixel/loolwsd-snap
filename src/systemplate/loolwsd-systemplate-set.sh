#!/bin/bash

set -e
set -x

#deploy resultant template in systemplate subfolder 
CHROOT=$(pwd)/../install/systemplate
# get collaboraoffice from stage folder
INSTDIR=$(pwd)/../../../stage/opt/collaboraoffice5.1

test -d "$INSTDIR" || { echo "No such directory: $INSTDIR"; exit 1; }

[ -e $CHROOT ] || mkdir $CHROOT || exit 1

CHROOT=`cd $CHROOT && /bin/pwd`
INSTDIR=`cd $INSTDIR && /bin/pwd`

cd / || exit 1

(
# Produce a list of file names, one per line, that will be copied
# into the template tree of system files for the chroot jails.

# First essential files and shared objects
find /etc/passwd /etc/group /etc/hosts \
     /etc/resolv.conf \
     /lib/ld-* /lib64/ld-* \
     /lib/libcap* /lib64/libcap* /lib/*-linux-gnu/libcap* \
     /lib/libattr* /lib/*-linux-gnu/libattr* \
     /etc/ld.so.* \
     /lib/libnss_* /lib64/libnss_* /lib/*-linux-gnu/libnss*\
     /var/cache/fontconfig \
     /etc/fonts \
     /etc/localtime \
     /usr/lib/locale/en_US.utf8 \
     /usr/lib/locale/C.UTF-8 \
     /usr/lib/locale/locale_archive \
     /usr/share/zoneinfo/* \
     /usr/share/liblangtag \
     /usr/lib/libpng* /usr/lib64/libpng* \
	 -type f

find /etc/fonts \
     /lib/ld-* /lib64/ld-* \
     /lib/libnss_* /lib64/libnss_* /lib/*-linux-gnu/libnss*\
     /lib/libcap* /lib/libcap* /lib64/libcap* /lib/*-linux-gnu/libcap* \
     /lib/libattr* /lib/*-linux-gnu/libattr* \
     /usr/lib/libpng* /usr/lib64/libpng* \
	 -type l

# Go through the LO shared objects and check what system libraries
# they link to.
find $INSTDIR -name '*.so' -o -name '*.so.[0-9]*' |
while read file; do
    ldd $file 2>/dev/null
done |
grep -v dynamic | cut -d " " -f 3 | grep -E '^(/lib|/usr)' | sort -u | sed -e 's,^/,,'
) |

# Can't use -l because then symlinks won't be handled well enough.
# This will now copy the file a symlink points to, but whatever.
cpio -p -d -L $CHROOT

mkdir -p $CHROOT/tmp
mkdir -p $CHROOT/usr/bin/

# /usr/share/fonts needs to be taken care of separately because the
# directory time stamps must be preserved for fontconfig to trust
# its cache.

cd $CHROOT || exit 1

# pwd is template path
mkdir -p usr/share || exit 1
cp -r -p -L /usr/share/fonts usr/share

if [ -h usr/share/fonts/ghostscript ]; then
    mkdir usr/share/ghostscript || exit 1
    cp -r -p -L /usr/share/ghostscript/fonts usr/share/ghostscript
fi

# Debugging only hackery to avoid confusion.
if test "z$ENABLE_DEBUG" != "z" -a "z$HOME" != "z"; then
    echo "Copying development users's fonts into systemplate"
    mkdir -p $CHROOT/$HOME
    test -d $HOME/.fonts && cp -r -p -L $HOME/.fonts $CHROOT/$HOME
fi

exit 0
