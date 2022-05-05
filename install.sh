#!/bin/bash
sudo cp -rf ../robot_scripts /home/$1/
sudo cp ./operation.sh /usr/local/bin/operation
sudo chmod +x /usr/local/bin/operation
sudo chmod +x ~/robot_scripts/Env_switch.sh