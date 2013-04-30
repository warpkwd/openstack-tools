#!/bin/bash
####################################################
# Author :  Emilien Macchi                         #
# License : Apache 2.0                             #
# Purpose : Move networks from Nova to Quantum     #
####################################################

#### Configuration ####

# Quantum API Access
QUANTUM_API_HOST=localhost
KEYSTONE_API_HOST=localhost

# Keystone Admin user authentification
OS_TENANT_NAME=admin
OS_USERNAME=admin
OS_PASSWORD=secrete
OS_AUTH_URL="http://$KEYSTONE_API_HOST:5000/v2.0/"

# Quantum API Access
QUANTUM_API_HOST=localhost

# Misc
TMP_DIR="/tmp/move-nova_to_quantum"
mkdir $TMP_DIR
cd $TMP_DIR

# Check is Quantum API V2 is running
API_VERSION=$(curl -s $QUANTUM_HOST:9696| awk '{print $5}'| cut -d'"' -f2)
if [[ $API_VERSION != "v2.0" ]]; then
    echo "Your Quantum endpoint does not use API V2."
    exit 1;
fi

# Get informations of all current networks
echo "All networks are going to be listed and saved :"
NETWORKS_LIST=$(nova-manage network list > images.list)
sed -i '1,3d' networks.list
sed -i '$d' networks.list
while read network
do
# TBD
done < networks.list

# For each tenant :
## Get informations of all Floating IP
## Get informations of all reserved Floating IP
## Get informations of all Security Groups
## Get informations of all private IP of VMs
## Suspend all instances

# Stop nova-network and delete virtual bridges
# Change configuration in nova.conf for using Quantum
# Restart nova-network

# For each tenant :
## Create a network and a subnet (with overlapping) for each tenant in Quantum
## Create ports for private IPs
## Associate ports with VMs (DB)
## Resume VMs
## Create Security Groups
## Reserve Floatings IP
## Associate Floatings IP


# Test all connectivity with VM

cd .. && rm -rf $TMP_DIR

