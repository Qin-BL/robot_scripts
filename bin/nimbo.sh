. ./base.sh
. ./network.sh
loop() {
    sleep 10
    echo "loop start..."
    initialize || return
    set_permissions
    if [ $? -eq 0 ]
    then
        reset_start
    elif [ $? -eq 1 ] && [ $is_started -eq 1 ]
    then
        echo "check start..."
        start_control
        sync_time
        start_hotspot
        echo "check finish..."
    fi
    echo "loop finish..."
}
start_network_checker &
pid=$!
while true
do
    ps -p $pid
    if [ $? -ne 0 ]
    then
        echo "restart network_checker"
        start_network_checker &
        pid=$!
    fi
    loop
done
