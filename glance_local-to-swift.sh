#!/bin/bash
####################################################
# Author :  Emilien Macchi                         #
# License : Apache 2.0                             #
# Purpose : Move image from local storage to Swift #
# Note :    Work only with at least Glance API v2  #
####################################################

# We need to be root
if [[ $EUID != 0 ]]; then
    echo "This script must be run as root."
    exit 1;
fi

#### Configuration ####

# Keystone Admin user authentification
OS_TENANT_NAME=admin
OS_USERNAME=admin
OS_PASSWORD=password
OS_AUTH_URL="http://localhost:5000/v2.0/"

# Glance Access
GLANCE_HOST=localhost

# Swift Access from Glance user
SWIFT_ENDPOINT="http://localhost:8080/v1"
SWIFT_USER=glance
SWIFT_PASSORD=secrete

# Misc
TMP_DIR="/tmp/glance_local-to-swift"
mkdir $TMP_DIR
cd $TMP_DIR

# Check is Glance API V2 is running
API_VERSION=$(curl -s $GLANCE_HOST:9292| awk '{print $5}'| cut -d'"' -f2)
if [[ $API_VERSION != "v2.0" ]]; then
    echo "Your Glance endpoint does not use API V2."
    exit 1;
fi

# Image Download + Image listing with ownership

IMAGES_LIST=$(glance image-list > images.list)
sed -i '1,3d' images.list
sed -i '$d' images.list
while read image
do
	ID=$(echo $image | awk '{print $2}')
	NAME=$(echo $image | awk '{print $4}')
      	DISK_FORMAT=$(echo $image | awk '{print $6}')
      	CONTAINER_FORMAT=$(echo $image | awk '{print $8}')
      	STATUS=$(echo $image | awk '{print $12}')
      	OWNER=$(glance image-show $ID | grep owner | awk '{print $4}')
	echo "$image $OWNER">>images-with-owner.list 
      	glance image-download $ID >$NAME.$DISK_FORMAT
done < images.list

mv images-with-owner.list images.list

# Modify Glance configuration from local to swift storage backend
sed 's/' /etc/glance/glance-api.conf
sed 's/' /etc/glance/glance-registry.conf


# Restart Glance
service glance-api restart
service glance-registry restart


# End of the script
cd .. && rm -rf $TMP_DIR
echo "Glances images have been moved from local to Swift backend."
