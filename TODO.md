# To Do

* Better error handling (eg hostname not configured)
* Config verify mode (rsync dry run)
* Backup verify (eg rsync force checksum + dry run mode + verbose)
* Decide on handling for failed backups (do we snapshot), or make a configurable option
* Create shortcut script for adding new hosts
* Simple backup runner

## Later

* Backup runner that respects the retention interval.
* Prototype scheduler / snapshot pruner.
* Rewrite in Python

## Much later

* Create web front end for managing basic tasks:
  - Browse backups / hosts
  - Add hosts
  - Restore
  - Manage configuraiton

