#!/usr/bin/env bash
#
# Benchmark "Interface Hot Plugging"
#
# Copyright © 2013 eNovance <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

# OpenStack Credentials
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=password
export OS_AUTH_URL="http://keystone:5000/v2.0/"

# Variables
VM_NAME="vm-test"
IMAGE_NAME="Cirros"
FLAVOR_ID="2"
KEY_NAME="emilien"
NETWORK_NAME="net-test"
SUBNET_NAME="sub-test"
SUBNET_CIDR="10.0.11.0/24"
PUBLIC_NETWORK="public_network_#1"

# Functions
create_Network () {
	quantum net-create $1
	quantum subnet-create --name $2 $1 $3
}

create_VM () {
	nova boot --poll --key_name $KEY_NAME --image $IMAGE_NAME --flavor $FLAVOR_ID $VM_NAME
	PUBLIC_IP=$(nova list | grep "$VM_NAME" | awk '{print $8}' | cut -d "=" -f 2)
	if ! timeout 60 sh -c "while ! ping -c1 $PUBLIC_IP  >/dev/null 2>&1; do :; done"; then
    		echo "Failed to ping the VM!"
    		exit 1
  	fi
}

add_NIC () {
	NET_ID=$(quantum net-show -F id $NETWORK_NAME | grep id | awk '{print $4}')
	nova interface-attach --net-id $NET_ID $VM_NAME
  	ssh cirros@$PUBLIC_IP "sudo -i udhcpc -i eth1"
  	sleep 10
}

show_Hotplug () {
 	 ssh cirros@$PUBLIC_IP "ip a"
 	 nova interface-list $VM_NAME
}

purge () {
	nova delete $VM_NAME
  	sleep 5
	quantum net-delete $NETWORK_NAME
}

# Let's go !
create_VM
create_Network $NETWORK_NAME $SUBNET_NAME $SUBNET_CIDR
add_NIC
show_Hotplug
purge
