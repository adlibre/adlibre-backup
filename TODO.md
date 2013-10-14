# To Do

These are some features that are planned for implementation.

## Soon

* Develop backup auto snapshoting to provide support for weekly / monthly / yearly style retention schemes 
* Config verify mode (rsync dry run)
* Backup verify (eg rsync force checksum + dry run mode + verbose)
* Fault tolerant backup runner
* ad hoc backups should (optionally) emit an email on completion
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
