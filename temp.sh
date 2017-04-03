#!/bin/bash

    my_hostname=$(grep ^Host collector.stats | awk '{print $2}' | sed 's/.*/\L&/' )
    my_license=$(grep "^License key" collector.stats | awk '{print $3}') # TODO check to see if this is a valid license for a supported system?
    my_license_type=$(echo $my_license | awk -F- '{print $1}')

    chost_rsf_service_name=$(grep "^0 Service" plugins/opthacrsf-1binrsfcli-i0-stat.out | awk '{print $3}' | sed -s 's/,//')
    chost_other=$(grep Host plugins/opthacrsf-1binrsfcli-i0-stat.out | sed 's/.*/\L&/' | awk {'print $2'} | sed "/^$my_hostname$/d")
    
echo $my_license_type
echo $chost_other

    chost_other_col_list=$(listcol -c=$my_license_type*$chost_other)
    for i in $(echo $chost_other_col_list);do
        chost_other_rsf_temp_service_name=$(grep "^0 Service" $i/plugins/opthacrsf-1binrsfcli-i0-stat.out | awk '{print $3}' | sed -s 's/,//')
        if [ $chost_rsf_service_name == $chost_other_rsf_temp_service_name ]; then
            chost_other_rsf_service_name=$chost_other_rsf_temp_service_name
            chost_other_col=$i
            break
        fi
    done
    echo $chost_other_col

