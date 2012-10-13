# Development Notes

## Architecture

* Bourne shell - fast prototyping
* Cron will be used for scheduling
* Most scripts perform single operation on a single host backup
* 'Runner' scripts will perform global operations across multiple host backups

## Proposed Directory Structure

* /backup/
* /backup/bin/ - scripts
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
