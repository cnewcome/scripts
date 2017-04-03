#!/bin/bash

for i in ~/upload/caselogs/*;do
    if [[ ! -s $i ]]; then
        rm -f $i
    fi
done

rm -f ~/upload/caselogs/*.md5
mkmd5_caselogs
