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
export OS_AUTH_URL="http://<keystone-fqdn>:5000/v2.0/"

# Variables
VM_NAME="vm-test"
IMAGE_NAME="Cirros"
FLAVOR_ID="2"
NETWORK1_NAME="net-test1"
SUBNET1_NAME="sub-test1"
SUBNET1_CIDR="10.0.1.0/24"
NETWORK2_NAME="net-test2"
SUBNET2_NAME="sub-test2"
SUBNET2_CIDR="10.0.2.0/24"

# Functions
create_Network () {
	quantum net-create $1
	quantum subnet-create --name $2 $1 $3
}

create_VM () {
	NET_ID=$(quantum net-show -F id $1 | grep id | awk '{print $4}')
	nova boot --poll --key_name test --image $IMAGE_NAME --flavor $FLAVOR_ID --nic net-id=$NET_ID $2
}

add_NIC () {
	NET_ID=$(quantum net-show -F id $1 | grep id | awk '{print $4}')
	nova interface-attach --net-id $NET_ID $2
}

test_Hotplug () {
	ping $1 -c5 -q
	if [ $? != 1 ]
	then
		echo "New interface is reachable!"
	else
		echo "Can't reach the new interface!"
		exit 1
	fi
}

purge () {
	nova delete $VM_NAME
	quantum subnet-delete $SUBNET1_NAME
	quantum subnet-delete $SUBNET2_NAME
	quantum net-delete $NET1_NAME
	quantum net-delete $NET2_NAME
}

# Let's go !
create_Network $NETWORK1_NAME $SUBNET1_NAME $SUBNET1_CIDR
create_Network $NETWORK2_NAME $SUBNET2_NAME $SUBNET2_CIDR
create_VM $NETWORK1_NAME $VM_NAME
add_NIC $NETWORK2_NAME $VM_NAME
# Todo(EmilienM) :
# test_Hotplug
purge
