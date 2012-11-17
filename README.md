# Adlibre Backup

A high performance snapshot based backup system for Linux and UNIX like
operating systems.

Designed with system administrators in mind.

#### The problem

Existing Rsync backup approaches (eg [Rsnapshot](http://www.rsnapshot.org/) /
[BackupPC](http://backuppc.sourceforge.net/)) don't scale and are hard to monitor
and maintain when used with dozens or hundreds of hosts.

They also don't elegantly handle ad hoc backups, nor do they facilitate quickly
adding and removing hosts.

#### Our solution

Our solution is centralised and agentless, so there is nothing to consume
resources on your hosts, and all configuration is managed on the backup server.

Utilises native ZFS (and later Btrfs) filesystem snapshots, and per host
filesystems for better performance, scalability and ease of management.

Backups can be run at anytime, with custom expiry and a short message so you
know why the backup was taken.

### Aims

* High performance and scalability. (Benchmarked faster than other Rsync backup
solutions. eg BackupPC, Rsnapshot etc.)
* Simplicity: Simple text based configuration. And simple files-on-disk
backup format.
* Aims to be a paranoid system administrator's best friend.

###  Features

* Agentless
* Utilises ZFS (and later Btrfs) native filesystem features, eg snapshot, dedup
and compression
* Uses [Rsync](http://en.wikipedia.org/wiki/Rsync) and
[SSH](http://en.wikipedia.org/wiki/OpenSSH) for transport
* Integration with monitoring tools such as Nagios and Icinga using NSCA passive
checks.
* Centralised configuration and management - all configuration and scheduling is
done on the backup server
* Ad hoc annotated backups - allows for ad hoc backups with an explanation as to
when or why the backup was taken and per backup retention periods
* Per host backup, retention and quota policies
* Per host configuration and logs stored with the snapshot
* Utilise LVM snapshots for performing atomic backups of Linux systems. See
[atomic.sh](https://github.com/adlibre/atomic-rsync/)

## Installation

This requires FreeBSD host or similar operating system with native ZFS support
and a dedicated zpool for storage. Future versions will support Linux and Btrfs.

Check out the source code into the root of your zpool and review
``./conf/backup.conf`` as necessary to set your zpool options.

## Usage

### Adding a host

``./bin/add-host.sh <hostname>``

Then customise the per host config in ``./hosts/<hostname>/c/backup.conf`` and
ssh options in ``~/.ssh/config`` if required.

### Removing a host

To immediately purge the host configuration and all backup data:

``zfs umount zfs-pool-name/hosts/<hostname> &&
zfs destroy zfs-pool-name/hosts/<hostname>``

To disable future backups and allow existing backups to expire in line with the
retention policy set _DEBUG=true_ in ``./hosts/<hostname>/c/backup.conf``. This
is the preferred method.

### Running an ad hoc backup of a single host

``./bin/backup.sh <hostname> <annotation> <expiry-in-days>``

### Running a backup of all hosts

``./bin/backup-runner.sh --all``

or multiple hosts

``./bin/backup-runner.sh <hostname> <hostname>...``

### Restoring

All backups are stored on disk in plain sight. So to restore all you need to do
is copy (or rsync) the files from the backup pool to your host.

To find a particular snapshot:

``./bin/list-backups.sh <hostname>``

eg:

    backup-host# ./bin/list-backups.sh vz01.adlibre.net
    example.com 2012-10-25-23:35:19-1351168519 1352377190 "first backup"
    example.com 2012-11-04-15:40:49-1352004049 1354418267 "before acme software upgrade"

The files are stored plainly within the ZFS snapshot:

    backup-host# ls -lah /backup/hosts/example.com/.zfs/snapshot
    total 3
    dr-xr-xr-x  4 root  wheel     4B Nov 17 15:14 .
    dr-xr-xr-x  4 root  wheel     4B Oct 16 20:18 ..
    drwxr-xr-x  5 root  wheel     5B Oct 16 20:18 2012-10-25-23:35:19-1351168519
    drwxr-xr-x  5 root  wheel     5B Oct 16 20:18 2012-11-04-15:40:49-1352004049
    
Just dive in and copy the files out of the snapshot:
    
    cd /backup/hosts/example.com/.zfs/snapshot/ && \
    rsync -aH --numeric-ids 2012-11-04-15:40:49-1352004049/ example.com:/restore-point/

## Status

This should be considered "alpha" status. Whilst fully functional, this is a
prototype writen in Bourne shell. Production use is not recommended unless
you're comfortable with getting your hands dirty.

It is planned that later versions will be rewritten in Python and will support
Btrfs on Linux.

See [TODO](https://github.com/adlibre/adlibre-backup/blob/master/TODO.md) and
[ISSUES](https://github.com/adlibre/adlibre-backup/blob/master/ISSUES.md) for
outstanding issues and current bugs.
