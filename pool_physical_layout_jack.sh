#!/bin/bash
### 2016-08-23 -- CRN - Basic script started to fill a quick need to map disk location in a zpool status output.
###                     It still needs a lot of work to make it useful for all collectors.

for i in $(egrep -e raidz[1-3] -e mirror -e logs -e spares -e cache -e pool: -e c[0-9]\+t[0-9A-F]\+d[0-9]\+ zfs/zpool-status-dv.out | sed -e 's/pool\: \(.*\)$/pool:\1/'  | awk '{print $1}');do 
   if [[ $i =~ ^c ]]; then 
      grep $i enclosures/nmc-c-show-lun-slotmap.out | awk '{print "  "$1, $2, "slot:"$3}'
      grep $i disk/hddisco.out -A25 | grep -e vendor -e product -e revision -e serial | awk '{print $2 " "}'
   else 
      echo -n $i
   fi
done

