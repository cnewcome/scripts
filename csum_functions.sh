#!/usr/bin/env bash
# functions for csummary
# 2016-11-01 - Benjamin Hodgens - initial 
# PERF related
# a weight of 20 makes no assumptions about issues; and TODO or higher is "go ahead and run Sparta".
# We subtract when issues are encountered which need to be resolved prior to running Sparta, printing results at the end
# array of strings/checklist of perf analysis prereqs to be printed at the end
# NOTE, we should be able to just 'source' this to use it from bash if we don't mess it up
# add a PERF req
perf_pre=('')
function perf_req() {
    perf_pre=("${perf_pre[@]}" "$1")
}
pweight="20"


my_pwd=$(pwd)

# Color (from ingestor)
C_UND=$(tput sgr 0 1)
C_RESET=$(tput sgr0)
C_BOLD=$(tput bold)
C_RED=$(tput setaf 1)
C_GREEN=$(tput setaf 2)
C_YELLOW=$(tput setaf 3)
C_BLUE=$(tput bold;tput setaf 4)
C_MAGENTA=$(tput setaf 5)
C_CYAN=$(tput setaf 6)
C_WHITE=$(tput setaf 7)

# NULL def for unavailable data files 
NULL="/dev/null" # TODO this variable should perhaps instead be an error redirected to stderr

# input: date of license expiration, human readable string
# output: a warning, if we're due a renewal
license_countdown () { 
    month_secs=2628000 # roughly how many seconds are in a month
    lic_epoch=$(date --date="$1" +%s)
    lic_tleft=$(echo "$lic_epoch - $(date +%s)" | bc )
    if [[ $lic_tleft -lt "0" ]]; then
        echo "***$C_UND ALL STOP:$C_RESET This license $C_RED expired already$C_RESET at $1!"
        echo
        echo "  Hostname: $my_hostname"
        echo "  License: $my_license"
        echo "  Appliance: $appl_version"
        echo
        echo "  - Please address with TAM as to whether this is a special case."
        if [[ $mgmt_override != "yes" ]]; then
            exit            
        fi
    elif [[ $lic_tleft -lt $month_secs ]]; then
        echo "***$C_RED DANGER!$C_RESET License expires in $(date --date="$lic_tleft" +%d) days on $(date --date="$1" +%u) "
        echo "      - Alert customer appliance management will become inoperable."
    elif [[ $lic_tleft -lt $(echo "$month_secs * 2" | bc ) ]]; then
        echo "* WARNING:$C_YELLOW license will expire in the next two months:$C_RESET $1"
    else
        echo "* License expiration: $1"
    fi
}
col_version () {
    if [[ -f $my_pwd/collector.stats ]]; then 
        version_collector=$(grep "^Collector" $my_pwd/collector.stats | cut -f 2 -d "(" | cut -f 1 -d ")")
    elif [[ -f $my_pwd/bundle.log ]]; then
        echo "This is a Bundle for NexentaStor 5"
        version_collector=""
    else
        echo "This isn't a valid Collector!"
        exit
    fi
    case $version_collector in
        # As of 2016-06-28, current version is 1.5.3
        1.5.[3-5])
        #    echo "Collector ($version_collector) is current."
        ;;
        1.5.[0-2])
            out="Collector ($version_collector) is (slightly)$C_YELLOW out of date$C_RESET. Please upgrade."
        ;;
        1.[1-2].[0-0])
            out="WARNING: Holy bats, cowman.$C_RED Upgrade the Collector $C_RESET (from stock $version_collector)!"
        ;;
        *) 
            if [[ -x $collector_version ]]; then
                out="WARNING: Collector ($version_collector) is$_RED SIGNIFICANTLY out of date$C_RESET . Please upgrade!"
            fi
        ;;
    esac
    echo $out
}
appl_version="NULL"
get_appl_version () { 
    if [[ -f "$my_pwd/collector.stats" ]]; then
        appl_version=$(grep ^"Appliance version" collector.stats | cut -f 2 -d "(" | cut -f 1 -d ")" | sed -e 's/v//')
    elif [[ -f "$my_pwd/bundle.json" ]]; then # TODO assume for now 
        appl_version="5.0"
        echo "NexentaStor 5.x bundle detected. Functionality is limited."
    fi
    case $appl_version in
    5.*)
        echo "Appliance ($appl_version) is supported but doesn't provide sufficient data for csummary. Functionality is reduced."
    ;;
    "4.0.4"*|"3.1.6"*)
        echo "Appliance ($appl_version) is supported!"
    ;;
    "3."*|"4.0."*) # all other versions, basically
        echo "Warning: Appliance $appl_version is no longer supported (or isn't a valid version)! Direct customer to upgrade and to review the portal."
        echo "Please involve your TAM and manager in supportability decisions."
        echo
        if [[ ! ($force_run = "yes") ]]; then
            echo $0
            exit
        fi
    ;;
    *)
    echo "Unable to detect appliance version ($appl_version)!"
    exit
    ;;
esac
}
# ---------------------------
# determine whether collector or bundle 
# per-format reusable and file path definitions go here!
# need a variable definition for every filetype in either collector.conf (3,4) or collector.json (5)
filename_init () {
    case $1 in 
        collector)
        ctype="collector"

        path_messages="kernel/messages"
        path_modparams="kernel/modparams.out"
        path_system="kernel/system"
        path_prtconf_v="pci_devices/prtconf-v.out"
        path_prtconf_v_stats="pci_devices/prtconf-v.stats"
        path_zfs_get_all="zfs/zfs-get-p-all.out"
        path_zpool_list="zfs/zpool-list-o-all.out"
        path_zpool_status="zfs/zpool-status-dv.out"
        path_zpool_history="zfs/zpool-history-il.out"
        path_echo_spa_c_mdb_k="zfs/echo-spa-c-mdb-k.out"
        path_kstat="kernel/kstat-p-td-10-6.out"
        path_autosaclog="go-live/nexenta-autosac.log"
        path_hddisco="disk/hddisco.out"
        path_iostat_en="disk/iostat-en.out"
        path_sasinfo_hba_v="hbas/sasinfo-hba-v.out"
        path_sasinfo_expander_tv="hbas/sasinfo-expander-tv.out"
        path_pkglist="system/dpkg-l.out"
        path_fcinfo_hba_port_l="hbas/fcinfo-hba-port-l.out"
        path_sesctl_enclosure="enclosures/sesctl-enclosure.out"
#        path_echo_arc_mdb="zfs/echo-arc-mdb-k.out"
        path_sharectlgetnfs="nfs/sharectl-get-nfs.out"
        path_showmount_a_e="nfs/showmount-a-e.out"
        path_nfsstat_s="nfs/nfsstat-s.out"
        path_rsfcli_i0_stat="plugins/opthacrsf-1binrsfcli-i0-stat.out"
        path_svcs_a="services/svcs-a.out"
        path_ptree_a="system/ptree-a.out"
        path_ifconfig_a="network/ifconfig-a.out"
        path_appl_replication="services/nmc-c-show-auto-sync-v.out"
        path_fmdump_evt_nday="fma/fmdump-evt-30day.out.gz"
        path_fmdump_evt_nday_stats="fma/fmdump-evt-30day.stats"
        path_echo_taskq_mdb_k="appliance/echo-taskq-mdb-k.out"
        path_stmfadm_list_target_v="comstar/stmfadm-list-target-v.out"
        path_sbdadm_list_lu="comstar/sbdadm-list-lu.out"
        path_sasinfo_hba_v="hbas/sasinfo-hba-v.out"
        path_sharectl_get_smb="cifs/sharectl-get-smb.out"
        path_fmadm_faulty="fma/fmadm-faulty.out"
        path_stmfadm_list_lu_v="comstar/stmfadm-list-lu-v.out"
        path_appliance_runners="appliance/nmc-c-show-appliance-runners.out"
        path_stmfadm_list_state="comstar/stmfadm-list-state.out"
        path_retire_store="fma/retire_store"
        path_lun_smartstat="disk/nmc-c-show-lun-smartstat.out"
        path_dladm_show_phys="network/dladm-show-phys.out"
        ;;
        bundle)
        ctype="bundle"
        path_messages="rootDir/var/adm/messages"
        path_modparams="kernel/modparams.out"
        path_system="rootDir/etc/system"
        path_prtconf_v="pci_devices/prtconf-v.out"
        path_prtconf_v_stats="$NULL"
        path_zfs_get_all="zfs/zfs_get-p_all.out"
        path_zpool_list="zfs/zpool_list-o_all.out"
        path_zpool_status="zfs/zpool_status-Dv.out"
        path_zpool_history="zfs/zpool_history-il.out"
        path_echo_spa_c_mdb_k="zfs/mdb-spa-c.out"
        path_kstat="kernel/kstat-p-Td.out"
        path_autosaclog="system/nexenta-autosac.log"
        path_hddisco="$NULL"
        path_iostat_en="disk/iostat-En.out"
        path_sasinfo_hba_v="$NULL"
        path_sasinfo_expander_tv="$NULL"
        path_pkglist="system/pkg_list.out"
        path_fcinfo_hba_port_l="hbas/fcinfo_hba-port-l.out"
        path_sesctl_enclosure="$NULL"
        path_echo_arc_mdb="zfs/mdb-arc.out"
        path_sharectlgetnfs="nfs/sharectl_get_nfs.out"
        path_showmount_a_e="nfs/showmount-a-e.out"
        path_nfsstat_s="nfs/nfsstat-s.out"
        path_rsfcli_i0_stat="ha/opt_HAC_RSF-1_bin_rsfcli-i0_stat.out"
        path_svcs_a="services/svcs-a.out"
        path_ptree_a="system/ptree-a.out"
        path_ifconfig_a="network/ifconfig-a.out"
        path_appl_replication="analytics/hprStats.json" # v5 exclusive
        path_fmdump_evt_nday="fma/fmdump-eVt_30day.out"
        path_fmdump_evt_nday_stats="$NULL"
        path_echo_taskq_mdb_k="kernel/mdb-taskq.out"
        path_stmfadm_list_target_v="comstar/stmfadm_list-target-v.out"
        path_sbdadm_list_lu="comstar/sbdadm_list-lu.out"
        path_sasinfo_hba_v="$NULL"
        path_nefclient_sas_select="disk/nefclient-sas_select.json" # v5 exclusive, all sasinfo stuff? 
        path_sharectl_get_smb="cifs/sharectl_get_smb.out"
        path_fmadm_faulty="fma/fmadm_faulty.out"
        path_stmfadm_list_lu_v="$NULL"
        path_appliance_runners="nef/workers.json"
        path_stmfadm_list_state="$NULL"
        path_retire_store="$NULL"
        path_lun_smartstat="$NULL"
        path_dladm_show_phys="network/dladm_show-phys.out"
        ;;
    esac 
}
# ==== actual stuff here ==== #
get_appl_version # TODO rewrite these perhaps
col_version
#echo "appl_version $appl_version"
case $appl_version in
    5.*)
        echo "Hey look, version 5.0."
        filename_init "bundle"
        echo "*** Note: diagnostic ability is limited due to Bundle format."
        my_license_features=$(python -m json.tool $my_pwd/nef/license.json | sed -e "1,/features/d" -e '/\}/,$d' -e 's/\"//g')
        license_expire=$(python -m json.tool $my_pwd/nef/license.json | grep expires | cut -f 4 -d \")
        my_license_type="" # needed for other node detection, perhaps not needed here
        my_hostname=$( cat $my_pwd/system/hostname.out )
        my_domain=$( cat $my_pwd/network/domainname.out )
        my_date=$(python -m json.tool bundle.json | grep created | cut -f 4 -d \")
        arc_meta_used=$(grep 'arc_meta_used' $path_echo_arc_mdb)
        arc_meta_limit=$(grep 'arc_meta_limit' $path_echo_arc_mdb)
        arc_meta_max=$(grep 'arc_meta_max' $path_echo_arc_mdb)
        uptime=""
        dumpd=""
        col_terminated="$NULL"
    ;;
    "4.0.4"*|"3.1.6"*|*) 
        if [[ -x $version_collector ]]; then
            echo "Unable to identify bundle/collector, exiting but defining static variables."
            exit
        fi
        filename_init "collector"
        # other variables we have defined historically 
        my_license=$(grep "^License key" collector.stats | awk '{print $3}') # TODO check to see if this is a valid license for a supported system?
        my_license_type=$(echo $my_license | awk -F- '{print $1}') # only used for finding other node bundle
        license_expire=$(/home/support/bin/keycheck.pl $(echo $my_license) | cut -f 2,3,4 -d ":")
        # TODO may also need to do something here about hostname case, it appears to differ shomehow between Collectors and filenames, and between hosts
        my_hostname=$(grep ^Host collector.stats | awk '{print $2}' | sed 's/.*/\L&/' )
        my_domain=$(cat nfs/domainname.out) # TODO this may be incorrect for non-NFS installs
        my_date=$(echo $my_pwd | awk -F_ '{print $3}' | sed -e 's/\(20[0-9]\{2\}-[0-1][0-9]-[0-3][0-9]\).*/\1/') # TODO my_date appears to sometimes be wrong on old Collectors
        arc_meta_used=$(grep 'arc_meta_used' zfs/echo-arc-mdb-k.out)
        arc_meta_limit=$(grep 'arc_meta_limit' zfs/echo-arc-mdb-k.out)
        arc_meta_max=$(grep 'arc_meta_max' zfs/echo-arc-mdb-k.out)
        arc_meta_used_num=$(echo $arc_meta_used | awk '{print $3}')
        arc_meta_limit_num=$(echo $arc_meta_limit| awk '{print $3}')
        arc_meta_max_num=$(echo $arc_meta_max | awk '{print $3}')
        uptime=$(cat system/uptime.out)
        dumpd=$(grep -e '^DUMPADM_DEVICE' kernel/dumpadm.conf)
        col_terminated=$(grep -H terminated */*.stats | grep -v smbstat | wc -l)
        ;;
    *)
        echo "Something went sideways with appliance version detection: appl_version $appl_version"
        exit
    ;;
esac



# misc variables, hopefully universal but we shall see won't we?
arc_meta_used_num=$(echo $arc_meta_used | awk '{print $3}')
arc_meta_limit_num=$(echo $arc_meta_limit| awk '{print $3}')
arc_meta_max_num=$(echo $arc_meta_max | awk '{print $3}')
mpt_sas_patch=$(grep driver-storage-mpt-sas $path_pkglist | awk '{print $3}' | awk -F. '{print $2}')

















