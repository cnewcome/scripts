#!/bin/bash
# Benjamin Hodgens

# get ashift and disk model for all disks in pools
# list of disks
disks=$(grep c[0-9] zfs/zpool-status-dv.out | awk {'print $1'})
for disk in $disks; do 
    ashift=$(egrep "ashift|$disk" zfs/echo-spa-c-mdb-k.out | grep -B1 $disk | grep ashift) 
    model=$(grep -A1 $disk disk/iostat-en.out | grep Vendor | sed -e 's/[ ,\n][a-z,A-Z]*: //g' -e 's/Serial.*//' -e 's/Vendor: //') # cut -f 4,5,6 -d ":" ) | sed -e 's/ [a-z,A-Z] //') 
    echo $disk
    echo $ashift
    echo $model
    echo 
done 
    
    

