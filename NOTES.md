# Development Notes

Development notes for the current Bourne shell implementation.

## Architecture

* Bourne shell - fast prototyping. Later versions will be written in Python.
* Cron is used for scheduling daily runs, and executing rotations (ala Rsnapshot)
* Most scripts perform a single operation on a single host backup
* 'Runner' scripts perform global operations across multiple host backups

## Directory Structure

* /backup/
* /backup/bin/ - program / scripts
* /backup/etc/ - global config
* /backup/hosts/ - hosts root
* /backup/hosts/example.com/ - ZFS / BTRFS subvolume
* /backup/hosts/example.com/c/ - per host config
* /backup/hosts/example.com/d/ - data root
* /backup/hosts/example.com/l/ - per host logs

## How to manage adding and removing hosts

In the case that a host is removed we have three options:

* purge - immediately remove all files and config.
* expire - stop future backups and expire existing backups in line with retention policy.
* disable - disable future backups and disable backup pruning.

## Scheduling

Cron is used to schedule the backup runner. It can be be set to run every hour
or as frequently as required for the backup interval.

## Snapshot / rotation

Snapshots are performed immediately after a successful backup run, or optionally
when `SNAPSHOT_ON_ERROR=true`.

Snapshot deletion is done in a separate process independently of the backup
processes (_bin/prune.sh_).

Snapshots are performed on a per host basis.

Partial / failed backups update the current host backup pool, but are not snapshotted
(unless SNAPSHOT_ON_ERROR=true).

Snapshot expiry is stateful and idempotent. It does not depend on
being run at the required rotation time. (eg as per Rsnapshot)

If snapshot is not pruned, then snapshots will accumulate indefinitely as frequently
as backups occur.

## ZFS Commands (cheat sheet)

    # setup backup zpool, set compression, set dedupe and inherit on backup/hosts
    # zfs create backup/hosts
    # zfs set compression=gzip backup
    # zfs set dedup=on backup
    # zfs inherit -r compression backup/hosts
    # zfs inherit -r dedup backup/hosts

    # zfs create backup/hosts/example.com
    # zfs snapshot backup/hosts/example.com@foo
    # zfs destroy backup/hosts/example.com@foo
