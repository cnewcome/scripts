#!/bin/bash
# 2016-05-26 - Newcomer - added the automation to output a letter to the customer with the correct commands to replace the disk.
#    This only works with a single disk failure at this time. If there are multiple disks failed, this will not work.
#    Call it by passing the string letter after the script name: failed_disk_loc.sh letter

function letter {
   printf "Begin formatted output:\n\n"
   printf "Hello,\n\n"
   printf "You have a failed drive at location:\n"
   printf "$DLOC\n\n"
   printf "Once physical location of the faulted drive is identified, offline the drive so it can be phyically removed:\n"
   printf "nmc$ setup volume $POOL offline-lun $DISK\n\n"
   printf "Physically remove the disk:\n$DLOC\n$DSIZE\n$DVEND\n$DPROD\n$DREVS\n$DSERL\n\n"
   printf "Insert new drive into the JBOD\n\n"
   printf "Clean up the device links\nnmc$ lunsync -r\n(if cluster, perform lunsync -r on other node)\n\n"
   printf "Find the NewDiskID by either tailing /var/adm/messages or running dmesg.\n\n"
   printf "Replace failed disk with new disk\n"
   printf "nmc$ setup volume $POOL replace-lun -o $DISK\n" 
   printf "Select the new disk from the list.\nThis will kick off a resilver.\n\n"
   if [[ ! -z $SPARE ]]; then
      printf "When the resilver is complete, detach the spare and return it to the spare pool.\n"
      printf "nmc$ setup volume $POOL detach-lun $SPARE\n\n"
   fi
   printf "You can check the status of the resilver with:\nnmc$ show volume $POOL status\n\n"
}

POOL=$(grep -B1 "^ state: DEGRADED" zfs/zpool-status-dv.out | grep pool | awk '{print $2}')
SPARE=$(grep spare- -A2 zfs/zpool-status-dv.out | tail -1 | awk '{print $1}')
CSEARCH=$(pwd | awk -F/ '{print $6}' | awk -F- '{print $4}')
DISKS=$(echo $* | sed -e 's/letter//')
DISKSID=$(echo $DISKS | sed -e 's/c[0-9]\+t//g')
NUMFAIL=$(echo $DISKS | wc -w)

echo searching for $NUMFAIL disks
echo $DISKS

if [[ $NUMFAIL -gt 0 ]]; then
    for i in $(ls -rd ~/ingested/20*); do
        CL=$(ls -d $i/*$CSEARCH* 2> /dev/null)
        for COL in $(echo $CL); do
        COLLECTOR=$(echo $COL | sed -e 's/.*collector/collector/')
            if [[ ! -z $(echo $COL|awk '{print $1}') ]]; then
                index=0
                for j in $(echo $DISKS); do
                    DID=$(echo $j | sed -e 's/c[0-9]\+t//g')
                    if [[ -e $COL/enclosures/nmc-c-show-lun-slotmap.out ]]; then
                        LOC=$(grep -i $DID $COL/enclosures/nmc-c-show-lun-slotmap.out | awk '{print $2, "slot:"$3}')
                        if [[ ! -z "${LOC}" ]] && [[ $(echo $LOC|awk '{print $1}') != "-" ]]; then
                            if [[ -z ${FOUND[$index]} ]]; then
                                FOUND=$((FOUND + 1))
                                echo ""
                                echo "Found in $COLLECTOR:"
                                DISK=$j
                                DLOC=$(echo "$j ${LOC}")
                                DSIZE=$(grep -i $DID $COL/disk/hddisco.out -A19 | egrep "size_str")
                                DVEND=$(grep -i $DID $COL/disk/hddisco.out -A19 | egrep "vendor")
                                DPROD=$(grep -i $DID $COL/disk/hddisco.out -A19 | egrep "product")
                                DREVS=$(grep -i $DID $COL/disk/hddisco.out -A19 | egrep "revision")
                                DSERL=$(grep -i $DID $COL/disk/hddisco.out -A19 | egrep "serial")
                                   echo $DLOC
                                   echo $DSIZE
                                   echo $DVEND
                                   echo $DPROD
                                   echo $DREVS
                                   echo $DSERL
                                if test $# -gt 1; then
                                   if [[ $1 == "letter" ]]; then
                                      letter
                                   fi
                                fi
                                if [[ $FOUND -eq $NUMFAIL ]]; then
                                    exit
                                fi
                            fi
                        fi
                    fi
                    ((index++))
                done
            fi
        done
    done
fi

