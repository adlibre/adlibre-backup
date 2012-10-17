# Adlibre Backup

A centralised, agentless, high performance snapshot based backup system for Linux and UNIX like operating systems.

#### The problem

Existing Rsync backup approaches eg [Rsnapshot](http://www.rsnapshot.org/) / [BackupPC](http://backuppc.sourceforge.net/) don't scale and are hard to monitor and maintain when used with dozens or hundreds of hosts.

#### Our solution

Utilise native ZFS (and later BTRFS) filesystem snapshots, and per host filesystems for better performance and ease of management.

###  Features

* Agentless
* Uses [Rsync](http://en.wikipedia.org/wiki/Rsync) and SSH for transport
* Centralised configuration and management - all configuration and scheduling is done on the backup server
* Per host backup, retention and quota policies
* Per host configuration and logs stored with the snapshot
* Utilise LVM snapshots for performing atomic backups of Linux systems
* Configuration verification (test configuration and host connectivity)

### Aims

* Better performance and scalability than backuppc, rsnapshot etc.
* Utilise ZFS (and later BTRFS) native filesystem features, eg snapshot, dedup and compression.
* Integration with monitoring tools such as Nagios and Icinga using NSCA passive checks.

### Status

Alpha (prototype) - still under active development. Whilst _backup.sh_ and _backup-runner.sh_ scripts work, the snapshot expiry and scheduler have not been developed.

## Installation

This requires FreeBSD host or similar operating system with native ZFS support. Future versions will support Linux and BTRFS.

Check out the source code and review as necessary to setup. It should be self explanatory. Better instructions will be written when this is beta status. 
