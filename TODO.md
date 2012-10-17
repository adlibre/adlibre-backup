# To Do

## Now

* Merge ./l/ and ./c/ dirs into ./v/
* Config verify mode (rsync dry run)
* Backup verify (eg rsync force checksum + dry run mode + verbose)

## Later

* Rewrite in Python
* Prototype scheduler / snapshot pruner.
* Backup runner that respects the retention interval.
* Decide on handling for failed backups (do we snapshot), or make a configurable option

## Much later

* Create web front end for managing basic tasks:
  - Browse backups / hosts
  - Add hosts
  - Restore
  - Manage configuraiton

