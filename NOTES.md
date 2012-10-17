# Development Notes

## Architecture

* Bourne shell - fast prototyping. Later versions will be written in Python.
* Cron will be used for scheduling daily runs, and executing rotations (ala Rsnapshot)
* Most scripts perform single operation on a single host backup
* 'Runner' scripts will perform global operations across multiple host backups

## Proposed Directory Structure

* /backup/
* /backup/bin/ - program / scripts
* /backup/etc/ - global config
* /backup/hosts/ - hosts root
* /backup/hosts/example.com/ - ZFS snapshot / filesystem 
* /backup/hosts/example.com/c/ - per host config
* /backup/hosts/example.com/d/ - data root
* /backup/hosts/example.com/l/ - per host logs

## How to manage adding and removing hosts

In the case that a host is removed we have two options:

* purge - immediately remove all files and config.
* expire - stop future backups and expire existing backups in line with retention policy.

## Snapshot / rotation

Snapshots are performed immediately after a successful backup run.

Snapshot deletion is done in a separate process independently of the backup processes.

Snapshots are performed on a per host basis.

We can optionally keep snapshots of partial / failed backups. Maybe just prepend 'failed' to the snapshot name.

## Scheduling

It is proposed that cron will be used at set to run every hour (or as frequently
as required for the minimal backup interval.

### Backups

Only if a backup job is required will a run be executed. (smart scheduler / pruner)

Alternatively we will backup everytime run, and the expiry of the backup will be set at the time the backup is taken. (eg default 7 day expiry.)
This means that monthly / quarterly / yearly backups need to be scheduled for a specific time to run. Otherwise the default expiry will apply.
(Dumb scheduler / pruner)

### Snapshot expiry (pruning)

Snapshot expiry will be stateful and idempotent, so they will not depend on
being run at the required rotation time. (eg as per Rsnapshot)

If snapshot is not run, then snapshots will accumulate indefinitely as frequently
as backups occur.

Snapshot expiry will be run independently of the backup process.

## ZFS Commands

# setup backup zpool, set compression, set dedupe and inherit on backup/hosts 
# zfs create backup/hosts
# zfs set compression=gzip backup
# zfs set dedup=on backup
# zfs inherit -r compression backup/hosts
# zfs inherit -r dedup backup/hosts

# zfs create backup/hosts/example.com
# zfs snapshot backup/hosts/example.com@foo
# zfs destroy backup/hosts/example.com@foo