# Known issues and bugs

* Multiple _BACKUP_PATHS_ does not work due to shell escaping issue with the rsync command.
* Lockfile removal on exit does not work with Bourne shell (is our implementation Bash specific?).