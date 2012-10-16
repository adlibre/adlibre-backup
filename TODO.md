# To Do

## Now

* Better error handling (eg hostname not configured)
* Decide on handling for failed backups (do we snapshot), or make a configurable option
* Create shortcut script for adding new hosts
* Config verify mode (rsync dry run)
* Backup verify (eg rsync force checksum + dry run mode + verbose)
* Collect timings (time taken) for each backup and pass this to nrpe as part of check result.
* Annotation feature (for one off backups) - eg. so you can do run a backup before and after an upgrade and know why they were taken

## Later

* Rewrite in Python
* Prototype scheduler / snapshot pruner.
* Backup runner that respects the retention interval.

## Much later

* Create web front end for managing basic tasks:
  - Browse backups / hosts
  - Add hosts
  - Restore
  - Manage configuraiton

