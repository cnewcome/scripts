#!/bin/bash

# author matthew green
# generate list of fmadm UUIDS to be acquitted, assumes all UUIDS are to be acquitted so beware
# must be run from <collector_name>/fma dir

for i in `egrep -e 'Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec' fmadm-faulty.out | awk '{print $4}'`;
    do
        echo "fmadm acquit" $i; 
    done

