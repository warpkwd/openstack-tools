#!/bin/bash
# Need to be add into bashrc of devstack server

login = adminsys
timeout = 5 # seconds

read -p "Start DevStack ? (y/N)? " -t $timeout stack

if [[ $stack = "y" ]]; then
    cd /home/$login/devstack && ./unstack.sh && ./stack.sh;
    else exit 0;
fi
