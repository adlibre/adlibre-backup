# Known issues and bugs

* Multiple __BACKUP_PATHS__ does not work due to shell escaping issue with the
rsync command.
* Lockfile removal on improper termination does not work with Bourne shell (is
our implementation Bash specific?).
