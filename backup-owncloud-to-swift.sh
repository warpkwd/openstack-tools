#!/bin/bash

export GPG_PUB_KEY="XXXX"
export OS_USERNAME="xxxx"
export OS_TENANT_NAME="XXXX"
export OS_AUTH_URL="https://identity.fr0.cloudwatt.com:443/v2.0"
export OS_PASSWORD="XXXX"
export OWNCLOUD_BASE="/home/owncloud"
export TMP_DIR=/tmp

usage () {
    echo "usage :$(basename $0) <name of ownCloud Directory to backup>"
    exit 1
}

backup_folder () {
    # Build an archive and compress it
    tar zcPf $TMP_DIR/$1.tar.gz $OWNCLOUD_BASE/$1
    # Encrypt the datas with GPG
    gpg -e -r $GPG_PUB_KEY --trust-model always $TMP_DIR/$1.tar.gz
    rm -rf $TMP_DIR/$1.tar.gz
    # Rename file to be supported by CloudWatt
    mv $TMP_DIR/$1.tar.gz.gpg $TMP_DIR/$1.backup
    echo "1) $1 compressed & encrypted, ready to be sent."
}

upload_file () {
    cd $TMP_DIR
    swift delete $1
    swift upload $1 $1.backup
    echo "2) Encrypted has been upload."
    rm -rf $1.backup
}

FOLDER=$1
[ -z "$FOLDER" ] && usage

backup_folder $FOLDER
upload_file $FOLDER
