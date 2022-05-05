echo "---------------Environments----------------------"
echo "            万达环境请输入：wanda                   "
echo "            保利环境请输入：poly                    "
echo "            国内dev环境：cndev                     "
echo "            国内test环境：cntest                   "
echo "            美国demo环境：usdemo                   "
echo "            美国test环境：ustest                   "
echo "-------------------------------------------------"

echo "please enter the environment your want to switch:"
read environment

username=$(whoami)
nav_host=192.168.0.1
nav_port=5555

if [ $environment == wanda -o $environment == poly -o $environment == cndev -o $environment == cntest -o $environment == usdemo -o $environment == ustest ]
then
    adb connect $nav_host
    adb -s $nav_host:$nav_port push ./robot_config/robot_config.txt.$environment /sdcard/android_robot/robot_config.txt
    adb -s $nav_host:$nav_port shell am force-stop com.turingvideo.robot
    adb -s $nav_host:$nav_port shell am start -n com.turingvideo.robot/com.turingvideo.robot.app.MainActivity

    cp ./robox_config/robox_config.yaml.$environment /home/$username/dist-robox_prod/robox/robox_config.yaml
    sudo systemctl restart robox
    echo "succeed"
else 
    echo "Your input is wrong!Please enter again"
    exit
fi
