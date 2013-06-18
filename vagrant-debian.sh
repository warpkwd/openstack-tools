#!/bin/bash

# Simple script to create and destroy a VM

VAGRANT_DIR='/home/emilien/.vagrant.d/vm_debian'

while getopts "cd" opt ; do
    case $opt in
        c ) ACTION=c ;;
        d ) ACTION=d ;;
        * ) echo "Bad parameter"
            exit 1 ;;
    esac
done


if [[ $ACTION = "c" ]]; then
    cd $VAGRANT_DIR; vagrant up; vagrant ssh;
fi

if [[ $ACTION = d ]]; then
    cd $VAGRANT_DIR; vagrant destroy -f;
fi
