# Adlibre Backup

A centralised, agentless, high performance snapshot based backup system for Linux and UNIX like operating systems.

#### The problem

Existing Rsync backup approaches eg [Rsnapshot](http://www.rsnapshot.org/) / [BackupPC](http://backuppc.sourceforge.net/) don't scale and are hard to monitor and maintain when used with dozens or hundreds of hosts.

#### Our solution

Utilise native ZFS (and later BTRFS) filesystem snapshots, and per host filesystems for better performance and ease of management.

### Aims

* Better performance and scalability than BackupPC, Rsnapshot etc.
* Utilise ZFS (and later BTRFS) native filesystem features, eg snapshot, dedup and compression.
* Integration with monitoring tools such as Nagios and Icinga using NSCA passive checks.
* Fault tolerant

###  Features

* Agentless
* Uses [Rsync](http://en.wikipedia.org/wiki/Rsync) and [SSH](http://en.wikipedia.org/wiki/OpenSSH) for transport
* Centralised configuration and management - all configuration and scheduling is done on the backup server
* Per host backup, retention and quota policies
* Per host configuration and logs stored with the snapshot
* Utilise LVM snapshots for performing atomic backups of Linux systems (see _rsync-lvm-snapshot.sh_)
* Configuration verification (test configuration and host connectivity) (TODO)
* Ad hoc annotated backups - allows for ad hoc backups with an explanation as to when or why the backup was taken and per backup retention periods

## Installation

This requires FreeBSD host or similar operating system with native ZFS support and a dedicated zpool for storage. Future versions will support Linux and BTRFS.

Check out the source code into the root of your zpool and review _./conf/backup.conf_ as necessary to setup.
It should be self explanatory. Better instructions will be written when this is beta status. 

## Configuration

### Adding a host

> ./bin/add-host.sh <hostname>

Then customise the config in _./hosts/<hostname>/c/backup.conf_.

### Removing a host

To immediately purge the host configuration and all backup data:

> zfs umount <zfs-pool-name>/hosts/<hostname> && zfs destroy <zfs-pool-name>/hosts/<hostname>

To disable future backups and allow existing backups to expire in line with the retention policy
set _DEBUG=true_ in _./hosts/<hostname>/c/backup.conf_. This is the preferred method.

## Status

This should be considered "alpha" status. Whilst functional, this is a prototype and is evolving rapidly, so production use is not recommended unless you're comfortable with getting your hands dirty.
