nimbo_host="192.168.0.1"
hotspot_host="192.168.0.2"
is_started=0
is_started_control=0

connect_nimbo() {
    adb disconnect $nimbo_host
    adb connect $nimbo_host || return 2
    adb -s $nimbo_host root || return 2
}

connect_interaction() {
    adb disconnect $hotspot_host
    adb connect $hotspot_host || return 2
    adb -s $hotspot_host root || return 2
}

initialize() {
    count=`adb devices|grep -e "\($nimbo_host\)\|\($hotspot_host\)"|wc -l` || return 2
    if [ $count -eq 2 ]
    then
        navigation_user=`adb -s $nimbo_host shell "whoami"` || return 2
        interaction_user=`adb -s $hotspot_host shell "whoami"` || return 2
        if [ $navigation_user = "root" ] && [ $interaction_user = "root" ]
        then
            echo "Skip initialize..."
            return
        fi
    fi
    echo "Perform connect nimbo and interaction..."
    connect_nimbo || return 2
    connect_interaction || return 2
    sleep 2
}

set_permission_for_navigation() {
    tmp=`adb -s $nimbo_host shell 'ls -l /dev/ttyS4| grep crwxrwxrwx | wc -l'` || return 2
    if [ $tmp -eq 1 ]
    then
        echo "Skip set_permissions"
        return 1
    fi
    echo "Perform set_permissions ..."
    adb -s $nimbo_host shell 'chmod 777 /dev/ttyS4 && setenforce 0' || return 2
}

set_permission_for_interaction() {
    tmp=`adb -s $hotspot_host shell 'ls -l /dev/snd| grep crwxrwxrwx | wc -l'` || return 2  # 2 is error
    if [ $tmp -gt 0 ]
    then
        echo "Skip set_permissions"
        return 1
    fi
    echo "Perform set_permissions ..."
    adb -s $hotspot_host shell 'chmod -R 777 /dev/snd &&  setenforce 0' || return 2  # 2 is error
}

set_permissions() {
    set_permission_for_navigation
    nav_res=`echo $?`
    set_permission_for_interaction
    int_res=`echo $?`
    if [ $nav_res -eq 2 ] || [ $int_res -eq 2 ]
    then
        return 2  # error
    elif [ $nav_res -eq 0 ] || [ $int_res -eq 0 ]
    then
        return 0
    else
        return 1
    fi
}

do_start_control() {
    tmp=`adb -s $nimbo_host shell "ps -ef|grep -a 'com.segway.robot.control'|grep -v grep|wc -l"` || return 2
    if [ $tmp -eq 0 ] || [ $is_started_control -eq 0 ]
    then
        echo "Start control ..."
        adb -s $nimbo_host shell am start -n com.segway.robot.control/.MainActivity || return 2
        is_started_control=1
    else
        echo "Skip start_control"
    fi
}


start_control() {
    now=$(date +%s)
    diff=$(expr $now - $start_time)
    if [ $diff -gt 30 ]  # 30 seconds
    then
        do_start_control
    else
        echo "Not ready for start_control: diff=$diff"
    fi
}

do_sync_time() {
    echo "Perform do_sync_time..."
    count=0
    while [ true ]; do
        count=`expr $count + 1`
        echo "count=$count"
        tt=`date +%s.%N`
        adb -s $nimbo_host shell "date -u '@$tt' || return 2"  # 1: connection error
        if [ $? -ne 2 ]
        then
            echo "do_sync_time break..."
            break
        fi
    done
}

is_synced_time=0

sync_time() {
    now=$(date +%s)
    diff=$(expr $now - $start_time)
    if [ $diff -gt 20 ]  # 20 seconds
    then
        if [ $is_synced_time -eq 0 ]
        then
            do_sync_time && is_synced_time=1
        else
            echo "Skip sync_time"
        fi
    else
        echo "Not ready for sync_time: diff=$diff"
    fi
}

do_start_hotspot() {
    tmp=`adb -s $hotspot_host shell 'dumpsys wifi | grep "curState=ApEnabledState" | wc -l '` || return 2
    if [ $tmp -eq 0 ]
    then
        echo "Perform do_start_hotspot..."
        adb -s $hotspot_host shell 'am start -n com.android.settings/.TetherSettings && input keyevent 20 && input keyevent 20 && input keyevent 66' || return 1
    else
        echo "Skip start_hotspot"
    fi
}


start_hotspot() {
    now=$(date +%s)
    diff=$(expr $now - $start_time)
    if [ $diff -gt 20 ]  # 20 seconds
    then
        do_start_hotspot
    else
        echo "Not ready for start_hotspot: diff=$diff"
    fi
    
}

reset_start() {
    start_time=$(date +%s)
    is_synced_time=0
    is_started_control=0
    is_started=1
    echo "reset_start: start_time=$start_time"
}
