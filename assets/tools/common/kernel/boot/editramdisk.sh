#!/sbin/sh
# Copyright 2016 Antoine GRAVELOT
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

mkdir /tmp/ramdisk
cp /tmp/boot.img-ramdisk.gz /tmp/ramdisk/
cd /tmp/ramdisk/
gunzip -c /tmp/ramdisk/boot.img-ramdisk.gz | cpio -i
rm /tmp/ramdisk/boot.img-ramdisk.gz
rm /tmp/boot.img-ramdisk.gz

if  ! grep -qr "noatime," /tmp/ramdisk/fstab_nodata.qcom; then
   sed -i "s/ro,/ro,noatime,/" /tmp/ramdisk/fstab_nodata.qcom
fi
# Disable dm-verity
sh /tmp/tools/kernel/boot/no-dm-verity.sh
# Disable force ecryption
sh /tmp/tools/kernel/boot/no-force-encrypt.sh

cd /tmp/ramdisk/
# Set FOS version
if  grep -qr "ro.oxygen.version=" /tmp/ramdisk/default.prop; then
   sed -i "s/ro.oxygen.version=.*/ro.oxygen.version=!version!/" /tmp/ramdisk/default.prop
fi

echo "" >> /tmp/ramdisk/init.rc
echo "setenforce 0" >> /tmp/ramdisk/init.rc

DEBUG=`grep "item.1.4" /tmp/aroma/mod.prop | cut -d '=' -f2`
if [ $DEBUG = 1 ]; then
  echo "persist.service.adb.enable=1" >> /tmp/ramdisk/default.prop
  echo "persist.service.debuggable=1" >> /tmp/ramdisk/default.prop
  echo "persist.sys.usb.config=mtp,adb" >> /tmp/ramdisk/default.prop
  #echo "ro.secure=0" >> /tmp/ramdisk/default.prop
  #echo "ro.adb.secure=0" >> /tmp/ramdisk/default.prop
fi

find . | cpio -o -H newc | gzip > /tmp/boot.img-ramdisk.gz
rm -r /tmp/ramdisk
