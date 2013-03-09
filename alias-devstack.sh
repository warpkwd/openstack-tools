#!/bin/bash
# Start & connecto to devstack VM (using VMware Workstation)

login = adminsys
DevStack = devstack.local
vm =  /home/emilien/Virtual\ Machines/DevStack/DevStack.vmx

alias ssh_devstack="ssh $login@$devstack"
alias start_devstack="vmrun -T ws start $vm"
alias devstack="start_devstack && sleep 15 && ssh_devstack"
