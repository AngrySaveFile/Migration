#!/bin/bash
uname -a
IN_USE=$(uname -a | awk '{ print $3 }')
echo "Your in-use kernel is $IN_USE"

OLD_KERNELS=$(
    dpkg --list |
        grep -v "$IN_USE" |
        grep -Ei 'linux-image|linux-headers|linux-modules' |
        awk '{ print $2 }'
)
echo "Old Kernels to be removed:"
echo "$OLD_KERNELS"

for PACKAGE in $OLD_KERNELS; do
     yes | apt purge "$PACKAGE"
apt autoremove -y
done
