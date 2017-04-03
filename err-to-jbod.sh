#!/bin/bash
# Ben Hodgens 1/2015
# uses paul's collector summary script and grep -p perl workalike
# identifies disk path and jbod based on errors as indicated on stdin

# doesn't work yet
guids=$(csummary | grepp $1 | cut -f 2 -d g)
for guid in $guids; do
    logical=$(grep -B20 $guid disk/hddisco.out | grep = | tail -n1 | sed -e s/=//)
    $enc_loc=$(grep -B150 $logical enclosures/nmc-c-show-jbod-all.out | egrep "$|alias" | tail -n2);
    jbod=$(grep alias $enc_loc)
    slot=$(grep $logical $enc_loc)
done
