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
The initcpio folder has to be merged into the one from the /etc folder and the /etc/mkinitcpio.conf needs the rootmnt hook at the end:

HOOKS=(... rootmnt)

It can be applied with the following command:
diff -ruN --color old new | patch -p1 -d /
### Info:
I'm not responsible, if anything doesn't work. Please test it yourself properly before using it, as it might destroy your system.

I'm using it myself for Arch-Linux with Syslinux boot loader. I haven't tested it yet on any other Linux distribution.