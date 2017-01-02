#!/bin/bash
# Script for nagios that matches the available mounts with the /etc/fstab file.
#
# Author: JR. Lambea
# Date:  20170102

mounts="$(cat /etc/fstab | grep "^//" | cut -d" " -f1)"
rc=0

for mount in $mounts; do
    $(mount | grep "^$mount" 1>&2 >/dev/null) || ( echo "${mount} KO"; rc=2 )
done

exit $rc
