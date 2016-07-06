# Adlibre Backup

A high performance snapshot based backup system for Linux and UNIX like
operating systems.

Designed with system administrators in mind.

Utilises native BTRFS / ZFS filesystem features for seamless compression,
deduplication and snapshoting of the backup pool.

#### The problem

Existing Rsync backup approaches (eg [Rsnapshot](http://www.rsnapshot.org/) /
[BackupPC](http://backuppc.sourceforge.net/)) don't scale, are hard to monitor
and maintain when used with dozens or hundreds of hosts.

They also don't elegantly handle ad hoc backups, nor do they facilitate quickly
adding and removing hosts.

#### Our solution

Our solution is centralised and agentless, so there is nothing to consume
resources on your hosts, and all configuration is managed on the backup server.

Utilises BTRFS / ZFS native filesystem snapshots, and per host
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
* Utilises BTRFS / ZFS filesystem features, eg snapshot, dedup
and compression
* Uses [Rsync](http://en.wikipedia.org/wiki/Rsync) and
[SSH](http://en.wikipedia.org/wiki/OpenSSH) for transport
* Integration with monitoring tools such as Nagios or Icinga using NSCA passive
checks.
* Centralised configuration and management - all configuration and scheduling is
done on the backup server
* Ad hoc annotated backups - allows for ad hoc backups with an explanation as to
when or why the backup was taken and per backup retention periods
* Per host backup, retention and quota policies
* Per host configuration and logs stored with the snapshot
* Utilise LVM snapshots for performing atomic backups of Linux systems. See
[atomic.sh](https://github.com/adlibre/atomic-rsync/) (Work in progress).

## Installation

An operating system with BTRFS or ZFS support is required (eg
[FreeBSD](http://www.freebsd.org) or [ZFS on Linux](http://zfsonlinux.org/))
and a dedicated storage pool.

Check out the source code into the root of your backup pool and review
``./conf/backup.conf``. Modify as necessary to set your pool and filesystem 
options.

### Red Hat / CentOS / EL Installation and ZFS Usage Example

Create _backup_ zpool with dedup and compression.

    zpool create -f backup vdb
    zfs set dedup=on backup
    zfs set compression=gzip backup

Install Adlibre Backup into root of _backup_ zpool.

    yum -y install git
    cd /backup && git clone git://github.com/adlibre/adlibre-backup.git .
    
Install NSCA Client (optional) for Nagios / Icinga integration

    yum -y install nsca-client

Generate SSH Key, this is used for authentication.

    ssh-keygen -t dsa -N "" -f ~root/.ssh/id_dsa
    
Add _server.example.com_ host config and copy the SSH Key to host example.com

    cd /backup && ./bin/add-host.sh example.com
    
Now run the backup

    ./bin/backup-runner.sh --all

The output

    [root@zbackup backup]# ./bin/backup-runner.sh --all
    Info: Begin backup run of hosts example.com
    Info: Begining backup of example.com
    Running: rsync -a --numeric-ids --hard-links --compress --delete-after --delete-excluded --fuzzy --exclude=/dev --exclude=/proc --exclude=/sys --exclude=/tmp --exclude=/var/tmp --exclude=/var/run --exclude=/selinux --exclude=/cgroups --exclude=lost+found root@example.com:'/' /backup/hosts/example.com/d/
    Warning: NSCA Plugin not found.
    Backup Successful. Runtime 1757 seconds.
    Warning: NSCA Plugin not found.
    Snapshot example.com@2013-06-14-15:12:39-1371186759 Created
    Info: Completed backup of example.com

That's it.

Now if you want to schedule daily backups Add the following to your root crontab:

    PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
    @daily /backup/bin/backup-runner.sh --all --comment "Backup Daily" && /backup/bin/prune.sh --all

## Usage

### Adding a host

``./bin/add-host.sh <hostname>``

Then customise the per host config in ``./hosts/<hostname>/c/backup.conf`` and
ssh options in ``~/.ssh/config`` if required.

### Removing a host (ZFS)

To immediately purge the host configuration and all backup data:

``zfs umount zfs-pool-name/hosts/<hostname> &&
zfs destroy zfs-pool-name/hosts/<hostname>``

To disable future backups and allow existing backups to expire in line with the
retention policy set _DISABLED=true_ in ``./hosts/<hostname>/c/backup.conf``.
This is the preferred method for host removal as it allows the old backups to
naturally expire.

### Running an ad hoc backup of a single host

``./bin/backup.sh <hostname> <annotation> <expiry-in-days>``

### Running a backup of all hosts

``./bin/backup-runner.sh --all``

or multiple hosts

``./bin/backup-runner.sh <hostname> <hostname>...``

### Restoring (ZFS)

All backups are stored on disk in plain sight. To restore all you need to do
is copy (or rsync) the files from the backup pool to your host.

To find a particular snapshot:

``./bin/list-backups.sh <hostname>``

eg:

    backup-host# ./bin/list-backups.sh example.com
    example.com 2012-10-25-23:35:19-1351168519 1352377190 successful "first backup"
    example.com 2012-11-04-15:40:49-1352004049 1354418267 successful "before acme software upgrade"

The files are stored plainly within the ZFS snapshot:

    backup-host# ls -lah /backup/hosts/example.com/.zfs/snapshot
    total 3
    dr-xr-xr-x  4 root  wheel     4B Nov 17 15:14 .
    dr-xr-xr-x  4 root  wheel     4B Oct 16 20:18 ..
    drwxr-xr-x  5 root  wheel     5B Oct 16 20:18 2012-10-25-23:35:19-1351168519
    drwxr-xr-x  5 root  wheel     5B Oct 16 20:18 2012-11-04-15:40:49-1352004049
    
Just dive in and copy the files out of the snapshot:
    
    cd /backup/hosts/example.com/.zfs/snapshot/ && \
    rsync -aH --numeric-ids 2012-11-04-15:40:49-1352004049/d/ example.com:/restore-point/

## Status

This has been in production use for many years now and is stable.

See [TODO](TODO.md) and [ISSUES](ISSUES.md) for outstanding issues.
And [NOTES](NOTES.md) for development information.
