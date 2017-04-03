#!/bin/bash

# Author - Andrew Galloway
# 2013-10-31 - last update

# reset IFS for carriage return only
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
DATE_COUNT=$(zgrep -B1 '^nvlist version' fmdump-evt-30day.out.gz | grep -v '\-\-\|nvlist' | awk '{print $1" "$2}' | sort -n | uniq -c | sort -n -r | head -3 | sort --sort=month)
for ENTRY in $DATE_COUNT; do
    DATE=`echo ${ENTRY} | awk '{$1=""; print $0}' | sed 's/^\ //'`
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

        if [ "${EVENT}" == "ereport.io.scsi.cmd.disk.tran" ]; then
            DISKS=$(zgrep -A10 "^$DATE" fmdump-evt-30day.out.gz | grep -A8 'class = ereport.io.scsi.cmd.disk.tran' | grep device-path | sort -n | uniq -c)

            for DISK in $DISKS; do
                echo -e "\t${DISK}"
            done
        fi
    done

    echo ""

    COUNT=$((COUNT + 1))
    if [ $COUNT -gt 3 ]; then
        break
    fi
done

IFS=$OLD_IFS
