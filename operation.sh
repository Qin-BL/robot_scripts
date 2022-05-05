#!/bin/bash

# This bash program is used for Turingvideo operation team to ease their job
# Author: Shaochong and Stella

# Edited by Stella Xu at 2020/4/02
# Android-S2 0.2.0 Edited by Zhichao Yu & Zack Li on 02/24/2020
# Android-S2 0.2.1 by Xiaocun Dong & Bilei Qin on 07/06/2021


# parameters:
tool_version="Android-S2 0.2.2"

# log file path
slam_log_path='/var/log/slam_server'
ros_log_path='/etc/ros_ws/log'
robox_log_path='/var/log/robox'
robot_power_service_log_path='/var/log/robot_power_service'


# Functions section

function function_list {
  echo     'menu                           the list of functions menu'
  echo     'status                         this will show you the status of this robot'
  echo     'pulllog                        this will pull the entire log folder'
  echo     'installcheck                   this will check if the files are correct during the installation process'
  echo     'network                        this will show you the internet download upload condition'
  echo     'localtime                      this will show the localtime of Robox and Nimbo'
  echo     'reboottime                     this will show you how long the Nimbo has been online, when the reboot was'
  echo     'livelog                        this will stream the live zenod log. Press ctrl+c to exit'
  echo     'pullnew                        this will pull the most recent Nimbo Log '
  echo     'restartapp                     this will kill the Nimbo App and restart it'
  echo     'localization                   this will show current localization status'
  echo     'restartslam                    this will kill the slam server and restart it'
  echo     'liveslamlog                    this will stream slam log in live'
  echo     'slamscore                      this will give you live location score. The lower the score, the more possible to lose location (will lose if <0.2)'
  echo     'landmark                       this will show you the list of landmarks in map recorded'
  echo     'markdetect                     this will tell you if the robot detects a landmark'
  echo     'videostatus                    this will show you the status of streaming service, ffmpeg'
  echo     'exit                           this will exit the program'
  echo  '   '
}

function status {
  robox_local_time=$(date)
  robox_version=$(cat ~/dist-robox_prod/robox/VERSION)
  ros_version=$(cat /etc/ros_ws/install_isolated/VERSION)
  slam_version=$(cat ~/dist-slam_server-prod/slam_server/VERSION)
  nimbo_service_version=$(cat ~/dist-nimbo/VERSION)
  system_version=$(lsb_release -rs)

  # Nimbo information
  robot_mac=$(cat /etc/zenod/robox/robot.json | cut -d' ' -f2 | cut -d',' -f1 | cut -d'[' -f2 | cut -d'"' -f2)
  robot_unformattedip=$(arp -n | grep $robot_mac)
  robot_ip=$(echo $robot_unformattedip | cut -d' ' -f1) #this is robot ip
  
  hotspot_host="192.168.0.2"


  adb connect $robot_ip:5555
  adb connect $hotspot_host:5555
  robot_version=$(adb -s $robot_ip:5555 shell dumpsys package com.turingvideo.robot | grep  versionName | cut -d'=' -f 2)
  robox_uptime_status=$(uptime)
  robot_local_time=$(adb -s $robot_ip:5555 shell date)
  robot_uptime=$(adb -s $robot_ip:5555 shell uptime)

  mediaservice_version=$(adb -s $hotspot_host:5555 shell dumpsys package com.turingvideo.mediaservice | grep  versionName | cut -d'=' -f 2)
  robot_voice_version=$(adb -s $hotspot_host:5555 shell dumpsys package com.turing.voice | grep  versionName | cut -d'=' -f 2)
  robot_interaction_version=$(adb -s $hotspot_host:5555 shell dumpsys package com.turingvideo.aiui | grep  versionName | cut -d'=' -f 2)
  nimbo_voice_version=$(adb -s $robot_ip:5555 shell dumpsys package com.turing.voice | grep  versionName | cut -d'=' -f 2)
  zenod_version=$(journalctl -u zenod|grep -o 'pinged [0-9]*.[0-9]*.[0-9]* robot_dog'|tail -1|awk '{print $2}')
  robot_power_service_version=$(cat ~/robot_power_service/VERSION)
  power_control_cli_version=$(power_manager -v)
  interaction_version=$(adb -s $hotspot_host shell getprop ro.build.display.id)
  navigation_version=$(adb -s $robot_ip shell getprop ro.build.display.id)

  echo '  '
  echo "=======  VERSION  ======="
  echo 'Robox:              '$robox_version
  echo 'Nimbo App:          '$robot_version
  echo 'Slam:               '$slam_version
  echo 'Ros:                '$ros_version
  echo 'nimbo_service:      '$nimbo_service_version
  echo 'media_service:      '$mediaservice_version
  echo 'tts_navigation:     '$robot_voice_version
  echo 'tts_interaction:    '$nimbo_voice_version
  echo 'voice-interaction:  '$robot_interaction_version
  echo 'Zenod:              '$zenod_version  
  echo 'Ubuntu:             '$system_version
  echo 'robot_power_service:'$robot_power_service_version
  echo 'power_control_cli:  '$power_control_cli_version
  echo 'interaction:        '$interaction_version
  echo 'navigation:         '$navigation_version

  echo '  '
  echo "========= STATUS ========"
  echo 'Nimbo IP:        '$robot_ip
  echo 'Robox localtime: '$robox_local_time
  echo 'Nimbo localtime: '$robot_local_time
  echo 'Robox uptime:    '$robox_uptime_status
  echo 'Nimbo uptime:    '$robot_uptime

}

function localtime {
   echo 'Robox localtime: '$robox_local_time
   echo 'Nimbo localtime: '$robot_local_time
}


function reboottime {
  echo "Uptime:"
  uptime
  echo "Last reboot time:"
  last reboot

}

function livelog {
  echo press ctrl+c to exit
    sleep 2
    journalctl -f -u zenod
}


function restartapp {
  echo please wait 20 seconds for system reboot
    adb connect $robot_ip:5555
    adb -s $robot_ip:5555 shell am force-stop com.turingvideo.robot
    sleep 5

    adb -s $robot_ip:5555 shell am start -n com.turingvideo.robot/.app.MainActivity
    sleep 5
    echo the robot is rebooted
}


function restartslam {
  echo "Do you want to restart the slam server? (y/n): "
    read slam_restart_confirm
    if [ $slam_restart_confirm == "y" ]
        then
        sudo systemctl restart slam_server
        echo "please wait 10 seconds for slam server to restart"
    else
        exit
    fi
}


function network {
  echo "If error occurs, make sure you have installed speedtest-cli"
  echo "the command to install is: sudo apt install speedtest-cli"
  speedtest-cli
}

function liveslamlog {
  journalctl -f
}

function slamscore {
  source /etc/ros_ws/install_isolated/setup.bash
  rostopic echo slam_status | grep localization_score
}

function landmark {
  source /etc/ros_ws/install_isolated/setup.bash
  rostopic echo /landmark_poses_list | grep id | grep -v -e frame_id
}


function markdetect {
  source /etc/ros_ws/install_isolated/setup.bash
  rostopic echo /landmark | grep id | grep -v -e frame_id

}

function videostatus {
  ffprobe rtsp://localhost:5580/live/main_camera
}


function localization {
  source /etc/ros_ws/install_isolated/setup.bash
  rostopic echo slam_status
}

function loglist {

    echo '    '
    echo '    '
    echo " Current log file list"
    echo
    echo
    echo "========== Ros's log files =========="
    ls -a $ros_log_path
    echo '    '
    echo '    '
    echo "====Slamserver's log files =========="
    ls -a $slam_log_path
    echo '    '
    echo '    '
    echo "====Robox's log files=========="
    ls -a $robox_log_path
    echo '    '
    echo '    '
    echo "====Nimbo's log files=========="
    adb -s ${robot_ip}:5555 ls /sdcard/android_robot/log/ > tmpfile.txt
    awk '{print $NF}' tmpfile.txt
    rm tmpfile.txt
    echo '    '
    echo '    '
    echo "====MediaService's log files=========="
    adb -s ${hotspot_ip}:5555 ls /sdcard/media_service/log/ > tmpfile_mediaservice.txt
    awk '{print $NF}' tmpfile_mediaservice.txt
    rm tmpfile_mediaservice.txt
    echo "====RobotpowerService's log files=========="
    ls -a $robot_power_service_log_path
    echo '    '
    echo '    '

}

function dldlog {

    logdate=""
    echo '    '
    echo '    '
    echo "Please type a keyword(date) for the log file"
    echo "(eg: 20210101 for all log files generated at 2021/01/01)"
    read logdate

    SUBSTR_YEAR=$(echo $logdate | cut -c1-4)
    SUBSTR_MONTH=$(echo $logdate | cut -c5-6)
    SUBSTR_DAY=$(echo $logdate | cut -c7-8)

    if [[ $SUBSTR_YEAR -gt 2000  ]] && [[ $SUBSTR_YEAR -lt 3000 ]]
    then

        # try remove if exists
        if [ $(find ./ -type d -name "*log_${SUBSTR_YEAR}*" | wc -l ) -gt -1 ]
        then
            rm -r *log_${SUBSTR_YEAR}*
        fi
        mkdir log_${logdate}
	    cd log_${logdate}
	    mkdir media_service_${logdate}
        mkdir nimbo_log_${logdate}
        mkdir robox_log_${logdate}
        mkdir slam_log_${logdate}
        mkdir ros_log_${logdate}
        mkdir robot_power_service_log_${logdate}

        # download log for nimbo
        cd nimbo_log_${logdate}
        adb -s $robot_ip:5555 shell ls /sdcard/android_robot/log/logcat_"${SUBSTR_YEAR}${SUBSTR_MONTH}${SUBSTR_DAY}"*.* | tr '\r' ' ' | xargs -n1 adb -s $robot_ip:5555 pull
        cd ../media_service_${logdate}
        adb -s $hotspot_host:5555 shell ls /sdcard/media_service/log/logcat_"${SUBSTR_YEAR}${SUBSTR_MONTH}${SUBSTR_DAY}"*.* | tr '\r' ' ' | xargs -n1 adb -s $hotspot_host:5555 pull
	    cd ..

        # download log for robox, slam and ros
        cp  $robox_log_path/robox.log ./robox_log_${logdate}
        cp  $robox_log_path/robox-err.log ./robox_log_${logdate}
        cp -R $robox_log_path/*${SUBSTR_YEAR}*${SUBSTR_MONTH}*${SUBSTR_DAY}* ./robox_log_${logdate}
        cp -R $slam_log_path/slam_server.log ./slam_log_${logdate}
        cp -R $slam_log_path/*${SUBSTR_YEAR}*${SUBSTR_MONTH}*${SUBSTR_DAY}* ./slam_log_${logdate}
        cp -R $ros_log_path/*${SUBSTR_YEAR}${SUBSTR_MONTH}${SUBSTR_DAY}* ./ros_log_${logdate}
        cp  $robot_power_service_log_path/* ./robot_power_service_log_${logdate}


        # mv all log folders to a central folder
        mv *_log_"${logdate}" log_${logdate}
        echo '   '
        echo 'Done!  '
        echo "Please check your log folder named as log_${logdate} at your robox"
        echo '  '
        echo 'If you want to download the log file to your laptop, please find the port number at zeno and enter following command at your local laptop terminal:'
        echo '  '
        echo  "scp -r -P <port number> box@test-zeno.turingvideo.com:~/log_${logdate} <local_path> "
        echo '  '

    else
        echo "Please enter a valid keyword "
        echo "(eg: 20190904 for all log files generated at 2019/09/04) or enter exit to exit. "
        read -r command

        if [ "${command}" == "exit" ]
        then
            echo ''
        else
            dldlog

        fi
    fi
}

function pulllog {

    slam_log_path='/var/log/slam_server'
    ros_log_path='/etc/ros_ws/log'
    robox_log_path='/var/log/robox'

    echo '    '
    loglist

    read -r -p "Do you want to download the log? (y/n):  " log_command

    if [ "$log_command" == "n" ]
    then
        echo '   '
    else
        dldlog
    fi
}

function installcheck {

    sudoer_file=""
    robot_config_file=""

    box_json_file=$(adb -s ${robot_ip}:5555 ls /sdcard/android_robot/key/prod/ | grep box.json | cut -d ' ' -f 4-)
    if [ -z "$box_json_file" ]
    then
      box_json_file="No such file or Nimbo is not online"
    else
      adb -s ${robot_ip}:5555 pull /sdcard/android_robot/key/prod/box.json ./
      robox_box_json_md5sum=$(md5sum /etc/zenod/robox/box.json | cut -d' ' -f -1)
      nimbo_box_json_md5sum=$(md5sum ./box.json | cut -d' ' -f -1)
      if [ "$robox_box_json_md5sum" == "$nimbo_box_json_md5sum" ]

      then
          box_json_file="Pass"
      else
          box_json_file="File content is wrong"
      fi

    fi

    # sudoer file check
    sudoer_content=$(md5sum /etc/sudoers.d/user_box | cut -d' ' -f -1)
    sudoer_file_16=cc1374a0a5ad5dbf06aace1e4639f4f2
    sudoer_file_18=792b344e81ccf42d455fea6b480f01a4


    echo "system version=${system_version}"

    if [ "${system_version}" == "18.04.2" ]
    then
        echo "sudoer_content=${sudoer_content}"
        echo "sudoer_file_18=${sudoer_file_18}"

        if [ "${sudoer_content}" == "${sudoer_file_18}" ]
        then
            sudoer_file='Pass'
        else
            sudoer_file="File is wrong"
        fi
    else
        if [ $sudoer_content == $sudoer_file_16 ]
        then
            sudoer_file='Pass'
        else
            sudoer_file="File is wrong"
        fi
    fi

    # robot_config_file check

    robot_json_file=$(adb -s ${robot_ip}:5555 ls /sdcard/android_robot/ | grep robot_config.txt | cut -d ' ' -f 4-)
    if [ -z "$robot_json_file" ]
    then
        robot_config_file="No such file"
    else
        pull_res=$(adb -s ${robot_ip}:5555 pull /sdcard/android_robot/robot_config.txt ~/)
        chmod +x robot_config.txt
        config_content=$(cat ~/robot_config.txt | grep database_endpoint)
        robot_config_file="$config_content"

    fi
    rm $robot_json_file

    #  Show the check result:
    echo '  '
    echo '  '
    echo '======  The content of box.json: ===='
    cat ./box.json
    rm box.json

    echo '  '
    echo '  '
    echo '======  The content of sudoer file: ===='
    cat /etc/sudoers.d/user_box

    echo '   '
    echo '   '
    echo '   '
    echo "==========  The result of installation check  ======="
    echo "                                               "
    echo "box.json file:       ${box_json_file}          "
    echo "Sudoer file:         ${sudoer_file}            "
    echo "robot_config.file: ${robot_config_file}        "
    echo "                                               "
    echo "===================================================="
    echo 'Done'

}

function pullnew {

  adb -s $robot_ip:5555 shell cat /sdcard/android_robot/log/logcat_*.txt

}


echo 'Nimbo basic status:'
echo '   '
status
echo '  '

echo "##########################  Welcome To Turing Operational Tool  ########################################"
echo "                                Tool Version:  ${tool_version}                                               "
adb connect ${robot_ip}:5555
while :
do

    task=""
    echo 'To view function list, type: menu'
    echo 'To use function, type: <function name>'
    echo 'To exit, type: exit'
    echo '    '
    read task
    echo

    case "$task" in

        "menu")
            function_list
        ;;
        "status")
            status
        ;;
        "localtime")
            localtime
        ;;
        "pulllog")
            pulllog
        ;;
        "reboottime")
            reboottime
        ;;
        "videostatus")
            videostatus
        ;;
        "livelog")
            livelog
        ;;
        "restartapp")
            restartapp
        ;;
        "restartslam")
            restartslam
        ;;
        "network")
            network
        ;;
        "searchinlog")
            searchinlog
        ;;
        "slamlog")
            slamlog
        ;;
        "slamlandmark")
            landmark
        ;;
        "slamdetection")
            markdetect
        ;;
        "localization")
            localization
        ;;
        "slamscore")
            slamscore
        ;;
        "installcheck")
            installcheck
        ;;
        "pullnew")
            pullnew
        ;;
        "liveslamlog")
            liveslamlog
        ;;
        "exit")
            adb disconnect
            exit
        ;;
        *)
            function_list
        ;;
    esac
    echo "    "
    echo "    "
    echo "    "
    echo "    "
done
