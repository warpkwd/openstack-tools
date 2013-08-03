#!/bin/bash
#
# Copyright (C) 2013
#
# Author: Emilien Macchi <emilien.macchi@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Require GPG & python-swiftclient
#
# Note: CloudWattCloud Storage does not support big files, that's why
# 	script split the files if bigger than 1GB.
#

export GPG_PUB_KEY="XXXX"
export OS_USERNAME="xxxx"
export OS_TENANT_NAME="XXXX"
export OS_AUTH_URL="https://identity.fr0.cloudwatt.com:443/v2.0"
export OS_PASSWORD="XXXX"
export OWNCLOUD_BASE="/home/owncloud/data/<user/files"
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

    # if the file is biggen than 1GB, we split it
    if [ $(stat -c %s $TMP_DIR/$1.backup) -gt 1073741824 ]
    then
        split --bytes=1G $TMP_DIR/$1.backup $TMP_DIR/$1.backup_split_
        rm $TMP_DIR/$1.backup
    fi

    echo "1) $1 compressed & encrypted, ready to be sent."
}

upload_file () {
    cd $TMP_DIR
    swift delete $1
    swift upload $1 $1.backup*
    echo "2) Encrypted has been upload."
    rm -rf $1.backup*
}

FOLDER=$1
[ -z "$FOLDER" ] && usage

backup_folder $FOLDER
upload_file $FOLDER
