#!/bin/sh
cd "$(dirname "$0")"

lowerdirs_loc=data/

if [ ! -z ${rootmnt_backup+x} ] || [ -n "$rootmnt_backup_sum" ]; then
  [ "$rootmnt_backup" != 1 ] && [ "$rootmnt_backup" != "" ] && custom_name="_$rootmnt_backup"
  backup_folder="$lowerdirs_loc`date "+%F_%H-%M"`$custom_name"
  mkdir "$backup_folder"
  if mksquashfs "overlay/upper" $backup_folder/root.sqfs; then
    rm -rf "overlay/upper.old"
    mv overlay/"upper" overlay/"upper.old"
    rm -r overlay/work
  fi
fi

# Get and mount all the sqfs files
lowerdirs=
for folder in $lowerdirs_loc*; do
  umount "$folder" 2> /dev/null
  sqfs=`ls "$folder"/*.sqfs 2> /dev/null`
  if [ -f "$sqfs" ]; then
    mount -o ro "$sqfs" "$folder"
    lowerdirs=$folder:$lowerdirs
  fi
done

# Create overlay folders if they don't exist
mkdir -p overlay/upper overlay/work

if [ -n "$rootmnt_backup_sum" ]; then
  [ "$rootmnt_backup_sum" != 1 ] && custom_name="_$rootmnt_backup_sum"
  backup_folder="`date "+%F_%H-%M"`$custom_name.all"
  mkdir -p /tmp/mount /tmp/upper /tmp/work
  mount -t overlay -o "lowerdir=${lowerdirs%:},upperdir=/tmp/upper,workdir=/tmp/work,noatime" overlay "/tmp/mount"
  if mksquashfs "/tmp/mount" $backup_folder/root.sqfs; then
    umount "$mount_point"
    umount $lowerdirs_loc*
    mkdir -p "backups"
    mv $lowerdirs_loc* "backups/"
    mv "$backup_folder" "$lowerdirs_loc"
    mount "$backup_folder/root.sqfs" "$lowerdirs_loc$backup_folder"
    lowerdirs="$lowerdirs_loc$backup_folder"
  fi
fi

# Change the mount point to tmp if a manual file exists (for manual access)
if [ ! -z ${rootmnt_edit+x} ]; then
  mount_point="tmp"
  mkdir -p "$mount_point"
  mount -t overlay -o "lowerdir=${lowerdirs%:},upperdir=overlay/upper,workdir=overlay/work,noatime" overlay "$mount_point"
  sh
  cd "$(dirname "$0")"
  umount "$mount_point"
  rm -r "$mount_point"
fi

if [ ! -z ${rootmnt_tmp+x} ]; then
  # If variable is set, mount it in a temporary environment - all changes done here will be lost
  rm -rf overlay/upper.tmp overlay/work.tmp
  mkdir overlay/upper.tmp overlay/work.tmp
  lowerdirs="overlay/upper:$lowerdirs"
  mount -t overlay -o "lowerdir=${lowerdirs%:},upperdir=overlay/upper.tmp,workdir=overlay/work.tmp,noatime" overlay .
else
  # Copy this file to the root folder (to also back up these changes)
  this_file=`basename "$0"`
  cp "$this_file" "/tmp/"
  mount -t overlay -o "lowerdir=${lowerdirs%:},upperdir=overlay/upper,workdir=overlay/work,noatime" overlay .
  diff "/tmp/$this_file" "`pwd`/root/$this_file" 2> /dev/null || cp "/tmp/$this_file" "`pwd`/root/$this_file"
fi
