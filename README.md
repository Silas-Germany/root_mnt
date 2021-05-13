# rootmnt

A tool to use the overlay filesystem for the root folder.

This makes it possible to create exact incremental backups of the whole system.

Also it enables the feature of a lifesystem like system, where every restart can reset the changes.

Those features can be selected as part of the boot options:

|Option|Function|
|---|---|
|rootmnt_tmp=1|Delete everything after next restart|
|rootmnt_backup=1|Does a backup with the current date & time as the folder name|
|rootmnt_edit=1|Opens the shell script to do any custom configuration, "exit" continues boot|

## Installation:
It requires the following options in /etc/mkinitcpio.conf:

BINARIES=(/usr/bin/date /usr/bin/mksquashfs)

HOOKS=(... rootmnt)