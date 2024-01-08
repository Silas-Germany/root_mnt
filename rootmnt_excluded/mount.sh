#!/bin/sh

# This scripts binds the folders to the target locations - so they are excluded from the overlay system

root="$1"

cd "$(dirname "$0")"
mkdir -p google-chrome_cache google-chrome_config JetBrains vbox docker swap

install -d "$root"/home
install -d -o 1000 -g 1000 "$root"/home/silas/.cache/google-chrome
mount -o bind ./google-chrome_cache "$root"/home/silas/.cache/google-chrome

install -d -o 1000 -g 1000 "$root"/home/silas/.config/google-chrome
mount -o bind ./google-chrome_config "$root"/home/silas/.config/google-chrome

install -d -o 1000 -g 1000 "$root"/home/silas/.cache/JetBrains
mount -o bind ./JetBrains "$root"/home/silas/.cache/JetBrains

mount -o bind ./vbox "$root"/home/silas/rev79/vbox

install -d "$root"/var/lib/docker
mount -o bind ./docker "$root"/var/lib/docker

mount -o bind ./swap "$root"/var/swap
