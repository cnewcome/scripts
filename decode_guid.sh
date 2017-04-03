#!/bin/bash

#DISK="/scsi_vhci/disk@g55cd2e404b7b351a"

GUID=$(echo $1 | sed -e 's/\/scsi_vhci\/disk@g//')
#CTD=$(grep $GUID disk/cfgadm-alv.out | grep connected | awk -F/ '{print $4}' | sed -e 's/(.*)//' -e 's/s0$//')
CTD=$(grep $GUID disk/hddisco.out -B49 | grep = | tail -1 | sed -e 's/=//')
grep $CTD enclosures/nmc-c-show-lun-slotmap.out
