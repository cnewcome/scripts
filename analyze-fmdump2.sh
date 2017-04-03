#!/bin/bash

set -x
# Author - Andrew Galloway
# 2013-10-31 - last update

# ammended 2014/4 Benjamin Hodgens

# reset IFS for carriage return only
TOPD=10
OLD_IFS=$IFS
IFS=$'\n'

if [ ! -f "fmdump-evt-30day.out.gz" ]; then
    echo "You are not in the proper directory - there is no fmdump-evt-30day.out.gz here."
    exit 1
fi

echo "Analyzing fmdump-evt-30day.out.gz..."

DATE_COUNT=$(zgrep -B1 '^nvlist version' fmdump-evt-30day.out.gz | grep -v '\-\-\|nvlist' | awk '{print $1" "$2}' | sort -n | uniq -c)

echo -e "  Count & Date"
echo "--------------"
for ENTRY in $DATE_COUNT; do
    echo ${ENTRY}
done

echo ""
echo "Unique error entry types for top 3 days"
echo "---------------------------------------"

COUNT=1
#DATE_COUNT=$(zgrep -B1 '^nvlist version' fmdump-evt-30day.out.gz | grep -v '\-\-\|nvlist' | awk '{print $1" "$2}' | sort -n | uniq -c | sort -n -r | head -n $TOPD)
DATE_COUNT=$(zgrep -B1 '^nvlist version' fmdump-evt-30day.out.gz | grep -v '\-\-\|nvlist' | awk '{print $1" "$2}' | sort -n | uniq -c | sort -n -r | head -3 | sort --sort=month)
for ENTRY in $DATE_COUNT; do
    DATE=`echo ${ENTRY} | awk '{$1=""; print $0}' | sed 's/^\ //'`
#for ENTRY in $DATE_COUNT; do
#    DATE=`echo ${ENTRY} | awk '{$1=""; print $0}' |  sed -r 's/^.*[0-9]+ //' | sort --month`
    echo "${DATE}:"

    ERROR_COUNT=$(zgrep "^${DATE}" fmdump-evt-30day.out.gz | awk '{print $5}' | sort -n | uniq -c | sort -n -r)

    for LINE in $ERROR_COUNT; do
        DISK=""

        echo ${LINE}
        EVENT=`echo ${LINE} | awk '{$1=""; print $0}' | sed 's/^\ //'`

        if [ "${EVENT}" == "ereport.fs.zfs.timeout" ]; then
            DISKS=$(zgrep -A18 "^$DATE" fmdump-evt-30day.out.gz | grep -A16 'class = ereport.fs.zfs.timeout' | grep vdev_path | sort -n | uniq -c)

            for DISK in $DISKS; do
                echo -e "\t${DISK}"
            done
        fi

        if [ "${EVENT}" == "ereport.io.pci.fabric" ]; then
            DISKS=$(zgrep -A18 "^$DATE" fmdump-evt-30day.out.gz | grep -A16 'class = ereport.io.pci.fabric' | grep device-path | sort -n | uniq -c)

            for DISK in $DISKS; do
                if [ $(echo $DISK | egrep "device.*(.*\/){4}|device.*(.*\/){5}") ]; then
                    echo -e "\t${DISK}" 
                fi
            done
        fi
        if [ "${EVENT}" == "ereport.io.scsi.cmd.disk.tran" ]; then
            DISKS=$(zgrep -A10 "^$DATE" fmdump-evt-30day.out.gz | grep -A8 'class = ereport.io.scsi.cmd.disk.tran' | grep device-path | sort -n | uniq -c)

            for DISK in $DISKS; do
                echo -e "\t${DISK}"
                DISK_SHORT=`echo $DISK | sed -e "s/^.*device-path.*disk@\(.*\),0/\1/"` #w###########
                DISKDEV=`grep -B30 $DISK_SHORT ../disk/hddisco.out | grep \= `
                DISKDEV=`echo $DISKDEV | cut -f 2 -d "="`
                echo -e "\t\t\tDISKDEV: ${DISKDEV}"
                DISK_JBOD=`grep -B1000 $DISK_SHORT ../enclosures/for-enclosure-in-sesctl-list-grep-v-enclosure_id-awk-print-1-do-echo-enclosure-sesctl-target_port-enclosure-done.out | grep -B1 "TARGET" | grep -v "TARGET" | tail -n 1`
                DISK_JBOD_NAME=`grep -B1000 $DISKDEV ../enclosures/nmc-c-show-jbod-all.out | grep alias | tail -n1`
                echo -e "\t\t\t${DISK_JBOD}"
                echo -e "\t\t\t${DISK_JBOD_NAME}"
            done
        fi
    done

    echo ""

    COUNT=$((COUNT + 1))
    if [ $COUNT -gt $TOPD ]; then
        break
    fi
done

IFS=$OLD_IFS
