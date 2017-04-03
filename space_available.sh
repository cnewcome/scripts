#!/bin/bash
# Collector will full zvols is: collector-T032-34FE5C0791-A457GDEGL-BLSJGP_ctnexenta1_2016-09-30.04-14-11EDT

FILESYSTEMS=$(grep type zfs/zfs-get-p-all.out | egrep "filesystem|volume" | grep -v "nza[-_]reserve" | awk '{print $1}')
for i in $FILESYSTEMS; do
    AVAILABLE=$(grep "$i " zfs/zfs-get-p-all.out | grep available | awk '{print $3}')
    USED=$(grep "$i " zfs/zfs-get-p-all.out | grep " used " | awk '{print $3}')
    if [[ $AVAILABLE -eq 0 ]]; then
        FULL_ZV=1
    fi
done
if [[ $FULL_ZV -eq 1 ]]; then
    echo "*** ZVOL SPACE WARNING"
    echo "One or more ZVOLs have no space available. Please check collector for more details."
    echo ""
fi
