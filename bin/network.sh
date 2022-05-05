network_host1="8.8.8.8"
huawei_router_host="192.168.8.1"
router_unreachable_time=0
network_unreachable_time=0
max_unreachable_time=150  # 2.5 min
local_network_timeout=5
public_network_timeout=15
robot_power_service_set_power='http://127.0.0.1:9033/device/devices/set_power'
runtime_info_file=~/dist-robox_prod/robox/runtime_info.yaml
disable_restart_router=0

do_restart_router() {
    result=`curl $robot_power_service_set_power -X POST -d '{"op": "reboot", "code_names": ["DevRS"], "sync": true}'`
    echo "Huawei router restart: $result"
    echo $result|grep '"dm":\ *"ok'
}

restart_router() {
    echo "enter restart_router..."
    # TODO: USE ${!1} IN BASH
    tmp=`eval echo '$'"$1"`
    if [ $tmp -eq 0 ]
    then
        eval "$1=$(date +%s)"
    else
        now=$(date +%s)
        diff=$(expr $now - $tmp)
        if [ $diff -gt $max_unreachable_time ]
        then
            if [ $disable_restart_router -eq 0 ]
            then
                do_restart_router
                if [ $? -eq 0 ]
                then
                    eval "$1=0"
                fi
            fi
        fi
    fi

}

network_checker() {
    ping -c 1 -W $local_network_timeout $nimbo_host
    if [ $? -ne 0 ]
    then
        echo "Navigation board unreachable..."
        return
    fi
    ping -c 1 -W $local_network_timeout $huawei_router_host
    if [ $? -ne 0 ]
    then
        echo "Huawei router unreachable..."
        restart_router "router_unreachable_time"
        return
    fi
    ping -c 1 -W $public_network_timeout $network_host1
    if [ $? -ne 0 ]
    then
        echo "$network_host1 unreachable..."
        if [ -f $runtime_info_file ]
        then
            web_domain=`grep 'web_domain' $runtime_info_file |grep -Eo "([a-zA-Z0-9_-]+\.)+([a-zA-Z0-9_-]+)"` && web_port=`grep 'web_port' $runtime_info_file |grep -Eo "[0-9]+"`
            if [ $? -ne 0 ]
            then
                echo "ERROR: process $runtime_info_file failed"
                return
            fi
            nc -w $public_network_timeout $web_domain $web_port  # because ping is disabled
            if [ $? -ne 0 ]
            then
                echo "$web_domain:$web_port unreachable..."
                restart_router "network_unreachable_time"
            fi
        else
            echo "waiting for runtime_info_file..."
        fi
    fi
}

start_network_checker() {
    while true
    do
        network_checker
        sleep 10
    done
}
