#!/usr/bin/env bash
#
# Benchmark "nova resize"
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

start=`date +%s`

# Spawn a small VM
echo " "
echo "We start a Small VM"
nova boot --poll --key_name test --image Cirros --flavor 2 scaling-test
if ! timeout 30 sh -c "while ! nova show scaling-test | grep status | grep -q ACTIVE; do sleep 1; done"; then
    echo "server didn't become active!"
    exit 1
fi
IP=$(nova show scaling-test | grep network | awk '{print $5}')
ping $IP>ping 2>/dev/null& pid=$!

# Resize the VM from small to Large
start1=`date +%s`
echo " "
echo "Resizing from Small to Large"
nova resize scaling-test 4
if ! timeout 30 sh -c "while ! nova show scaling-test | grep status | grep -q RESIZE; do sleep 1; done"; then
    echo "Resize failed."
    exit 1
fi

# Confirm Resizing
echo " "
echo "Confirm resizing"
if ! timeout 30 sh -c "while ! nova show scaling-test | grep status | grep -q VERIFY_RESIZE; do sleep 1; done"; then
    echo "Resize failed."
    exit 1
fi
nova resize-confirm scaling-test
if ! timeout 30 sh -c "while ! nova show scaling-test | grep status | grep -q ACTIVE; do sleep 1; done"; then
    echo "Resize failed."
    echo 1
fi
end1=`date +%s`
runtime1=$((end1-start1))

kill -INT $pid 2>/dev/null
lost1=$(grep transmitted ping)

echo " "
echo "The VM has been resized from small to large:"
nova show scaling-test
echo " "

# Resize the VM from Large to Tiny
start2=`date +%s`
ping $IP>ping 2>/dev/null& pid=$!
echo " "
echo "Resizing from Large to Tiny"
nova resize scaling-test 1
if ! timeout 30 sh -c "while ! nova show scaling-test | grep status | grep -q RESIZE; do sleep 1; done"; then
    echo "Resize failed."
    exit 1
fi

# Confirm Resizing
echo " "
echo "Confirm resizing"
if ! timeout 30 sh -c "while ! nova show scaling-test | grep status | grep -q VERIFY_RESIZE; do sleep 1; done"; then
    echo "Resize failed."
    exit 1
fi
nova resize-confirm scaling-test
if ! timeout 30 sh -c "while ! nova show scaling-test | grep status | grep -q ACTIVE; do sleep 1; done"; then
    echo "Resize failed."
    echo 1
fi
end2=`date +%s`
runtime2=$((end2-start2))

kill -INT $pid 2>/dev/null
lost2=$(grep transmitted ping)

echo " "
echo "The VM has been resized from Large to Tiny:"
nova show scaling-test
echo " "

# We delete the instance
nova delete scaling-test
rm ping

end=`date +%s`
runtime=$((end-start))

echo " "
echo "Resizing has been finished with success !"
echo " "

echo "Total time : $runtime seconds"
echo "Resize from Small to Large : $runtime1 seconds"
echo "Resize from Large to Tiny : $runtime2 seconds"
echo " "
echo "Network Stats during Small to Large resizing :"
echo $lost1
echo " "
echo "Network Stats during Large to Tiny resizing :"
echo $lost2
