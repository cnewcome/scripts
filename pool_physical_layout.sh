#!/bin/bash
### 2016-08-23 -- CRN - Basic script started to fill a quick need to map disk location in a zpool status output.
###                     It still needs a lot of work to make it useful for all collectors.

for i in $(egrep -e raidz[1-3] -e mirror -e logs -e spares -e cache -e pool: -e c[0-9]\+t[0-9A-F]\+d[0-9]\+ zfs/zpool-status-dv.out | sed -e 's/pool\: \(.*\)$/pool:\1/'  | awk '{print $1}');do 
   if [[ $i =~ ^c[0-9] ]]; then 
      DISK=$(grep $i enclosures/nmc-c-show-lun-slotmap.out | awk '{print "  "$1, $2, "slot:"$3}')
   else 
      DISK=$i
   fi
   VENDOR=$(grep $i disk/hddisco.out -A19 | grep vendor | awk '{print "- "$2}')
   PRODUCT=$(grep $i disk/hddisco.out -A19 | grep product | awk '{print $2 " -"}')
   REVISION=$(grep $i disk/hddisco.out -A19 | grep revision | awk '{print $2}')
   SERIAL=$(grep $i disk/hddisco.out -A19 | grep serial | awk '{print $2 " -"}')
   printf "$DISK $VENDOR $PRODUCT $SERIAL $REVISION\n"
done
