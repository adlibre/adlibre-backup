# Adlibre Backup

A centralised, agentless, high performance snapshot based backup system for Linux and UNIX like operating systems.

###  Features

* Agentless
* Uses Rsync and SSH for transport
* Centralised configuration and management - all configuration and scheduling is done on the backup server
* Per host backup, retention and quota policies
* Per host configuration and logs stored with the snapshot
* Utilise LVM snapshots for performing atomic backups of Linux systems

### Aims

* Better performance and scalability than backuppc, rsnapshot etc.
* Utilise ZFS / BTFS native filesystem features, eg snapshot, dedup, compression.
* Native integration with monitoring tools such as Nagios and Icinga.

### Status

Alpha - still in development.

## Installation

This requires FreeBSD host or similar operating system with native ZFS support. Future versions will support Linux and BTRFS.

Check out the source code and review as necessary to setup. It should be self explanatory. Better instructures will be written when this is beta status. 
