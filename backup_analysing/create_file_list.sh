#!/bin/bash

[ -d explanations ] || cd ..
[ -d explanations ] || exit 1

# Save files:
mkdir -p mount
mount -o ro root.sqfs mount
find mount -type b,p,f,l,s -printf "%k %p\n" \
    | grep -v '^[0-4] ' \
    | sed "s:[0-9]* *mount/::" \
    | sort -u \
    > /tmp/f1

# List installed / updated package files:
mkdir -p explanations
echo "# "$(for p in mount/var/lib/pacman/local/*/desc; do
  head -n 2 $p | tail -n 1
done) > explanations/pkgs

for files in mount/var/lib/pacman/local/*/files; do
  cat $files
done \
    | sort -u \
    > /tmp/f2
umount mount

# Create a file for each file location:
rm -f files/*
comm -23 /tmp/f? > file_changes
