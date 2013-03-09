#!/bin/bash
# Need to be add into bashrc of devstack server

read -p "Start DevStack ? (y/N)? " -t 10 stack

if [[ $stack = "y" ]]; then
    cd /home/adminsys/devstack && ./unstack.sh && ./stack.sh;
    else exit 0;
fi
