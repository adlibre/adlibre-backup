# To Do

These are some features that have been considered for implementation. It is likely that
many of these will never be implemented simply because this tool has proven itself to be sufficiently robust
and useful without these features:

## Earlier
* Support for send/receive (ZFS/Brfs) backup transport.
* Config verify mode (rsync dry run)
* Backup verify (eg rsync force checksum + dry run mode + verbose)
* Fault tolerant backup runner (eg retries)
* nohup should be used for ad hoc backups so they are not accidentally
terminated when run interactively.

## Later

* Rewrite in Python
* Prototype backup runner that respects the retention interval / advanced
snapshot pruner.
* Decide on handling for failed backups (do we snapshot), or make a configurable
option
* Make NSCA notifications optional by moving to a plugin / hook architecture

## Much later

* Create web front end for managing basic tasks:
  - Browse backups / hosts
  - Add hosts
  - Restore
  - Manage configuration
