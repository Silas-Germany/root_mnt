#!/bin/sh
cd "$(dirname "$0")"
mkdir -p data

mksquashfs_options="-mem 5500M -noappend -comp xz -xattrs -exit-on-error"

# Make a backup, if the flag is set - with the name as an additional suffix, if it's not "1"
if [ -n "$rootmnt_backup" -o -n "$rootmnt_backup_sum" ]; then
  [ "$rootmnt_backup" != 1 -a -n "$rootmnt_backup" ] && custom_name="_$rootmnt_backup"
  [ "$rootmnt_backup_sum" != 1 -a -n "$rootmnt_backup_sum" ] && custom_name="_$rootmnt_backup_sum"
  backup_folder="data/$(date -u "+%F_%H-%M")$custom_name"
  mkdir "$backup_folder"
  if mksquashfs "overlay/upper" "$backup_folder/root.sqfs" $mksquashfs_options; then
    rm -rf "overlay/upper" "overlay/work"
  else
    rm -rf $backup_folder
  fi
fi

mkdir -p overlay/upper overlay/work

# Get all the lowerdirs as root.sqfs files in folders of the data folder
lowerdirs=
for folder in data/*; do
  umount "$folder" 2> /dev/null
  if [ -f "$folder/root.sqfs" ]; then
    mount -o ro "$folder/root.sqfs" "$folder"
    lowerdirs="$folder:$lowerdirs"
  fi
done
[ -z "$lowerdirs" ] && lowerdirs=data

# Create overlay folders if they don't exist
if [ -n "$rootmnt_backup_sum" ]; then
  [ "$rootmnt_backup_sum" != 1 ] && custom_name="_$rootmnt_backup_sum"
  backup_folder="$(date -u "+%F_%H-%M")$custom_name.all"
  mount_point="/tmp/root"
  mkdir -p "$backup_folder" "$mount_point" /tmp/upper /tmp/work
  mount -t overlay -o "lowerdir=${lowerdirs%:},upperdir=/tmp/upper,workdir=/tmp/work,noatime,metacopy=on" overlay "$mount_point"
  if mksquashfs "$mount_point" "$backup_folder/root.sqfs" $mksquashfs_options; then
    umount "$mount_point"
    umount data/*
    mkdir -p "backups"
    mv data/* "backups/"
    mv "$backup_folder" "data/"
    mount "data/$backup_folder/root.sqfs" "data/$backup_folder"
    lowerdirs="data/$backup_folder"
  else
    rm -rf $backup_folder
  fi
fi

# Change the mount point to tmp if the flag is set (for manual access)
if [ -n "$rootmnt_edit" ]; then
  mount_point="/tmp/root"
  mkdir -p "$mount_point"
  mount -t overlay -o "lowerdir=${lowerdirs%:},upperdir=overlay/upper,workdir=overlay/work,noatime,metacopy=on" overlay "$mount_point"
  sh
  cd "$(dirname "$0")"
  umount "$mount_point"
  rm -d "$mount_point"
fi

if [ -n "$rootmnt_tmp" ]; then
  if [ "$rootmnt_tmp" = "1" ]; then
    # If variable is set to "1", mount it in a temporary environment - all changes done here will be lost on next tmp boot
    tmp_folder="overlay/tmp"
    rm -rf "$tmp_folder/upper" "$tmp_folder/work"
    mkdir -p "$tmp_folder/upper" "$tmp_folder/work"
    lowerdirs="overlay/upper:$lowerdirs"
    mount -t overlay -o "lowerdir=${lowerdirs%:},upperdir=overlay/tmp/upper,workdir=overlay/tmp/work,noatime,metacopy=on" overlay .
  else
    # If variable is set to something else mount in a temporary environment build on the last backup
    tmp_folder="overlay/tmp/$rootmnt_tmp"
    mkdir -p "$tmp_folder/upper" "$tmp_folder/work"
    [ ! -f "$tmp_folder/lowerdirs" ] && echo -n ${lowerdirs} > "$tmp_folder/lowerdirs"
    lowerdirs="$(cat "$tmp_folder/lowerdirs")"
    mount -t overlay -o "lowerdir=${lowerdirs%:},upperdir=$tmp_folder/upper,workdir=$tmp_folder/work,noatime,metacopy=on" overlay .
  fi
else
  # Copy this file to the root folder, if it's different (to also back up these changes)
  filename="$(basename "$0")"
  cp "$filename" "/tmp/"
  mount -t overlay -o "lowerdir=${lowerdirs%:},upperdir=overlay/upper,workdir=overlay/work,noatime,metacopy=on" overlay . || exit 1
  diff -q "/tmp/$filename" "$(pwd)/root/$filename" 2> /dev/null || cp "/tmp/$filename" "$(pwd)/root/$filename"
fi
