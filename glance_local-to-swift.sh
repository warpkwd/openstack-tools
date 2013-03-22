#!/bin/bash
####################################################
# Author :  Emilien Macchi                         #
# License : Apache 2.0                             #
# Purpose : Move image from local storage to Swift #
# Note :    Work only with at least Glance API v2  #
####################################################

#### Configuration ####

# Keystone Admin user authentification
OS_TENANT_NAME=admin
OS_USERNAME=admin
OS_PASSWORD=secrete
OS_AUTH_URL="http://localhost:5000/v2.0/"

# Glance API Access
GLANCE_API_HOST=localhost
GLANCE_USER=root

# Swift Access from Glance user
SWIFT_USER="glance:glance"
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

echo "All images are going to be downloaded :"
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
	echo "Downloading : $NAME.$DISK_FORMAT ..."
      	glance image-download $ID >$NAME.$DISK_FORMAT
	glance image-delete $ID
done < images.list
mv images-with-owner.list images.list

# Modify Glance configuration from local to swift storage backend
echo "-> Updating of glance-api.conf"
ssh $GLANCE_USER@$GLANCE_API_HOST "sed -e 's/\(default_store *= *\).*/swift/' \
	-e 's/\(swift_store_auth_address *= *\).*/\1$OS_AUTH_URL/' \
	-e 's/\(swift_store_user *= *\).*/\1$SWIFT_USER/' \
	-e 's/\(swift_store_key *= *\).*/\1$SWIFT_KEY/' \ 
	-e 's/\(swift_store_create_container_on_put *= *\).*/True/' /etc/glance/glance-api.conf"

# Restart Glance
echo "-> Restarting Glance API Service"
ssh $GLANCE_USER@$GLANCE_API_HOST "service glance-api restart"

# Upload images into Swift
while read image
do
        ID=$(echo $image | awk '{print $2}')
        NAME=$(echo $image | awk '{print $4}')
        DISK_FORMAT=$(echo $image | awk '{print $6}')
        CONTAINER_FORMAT=$(echo $image | awk '{print $8}')
        STATUS=$(echo $image | awk '{print $12}')
	OWNER=$(glance image-show $ID | grep owner | awk '{print $14}')
	glance image-create --id=$ID --name=$NAME --disk_format=$DISK_FORMAT --container_format=$CONTAINER_FORMAT \
		--owner=$OWNER --is-public=True < $NAME.$DISK_FORMAT
done < images.list

# End of the script
cd .. && rm -rf $TMP_DIR
echo "Glance images have been moved from local to Swift backend."
