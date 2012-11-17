# Known issues and bugs

* Multiple _BACKUP_PATHS_ does not work due to shell escaping issue with the
rsync command.
* Lockfile removal on termination does not work with Bourne shell (is our
implementation Bash specific?).
* Master log file does not capture per host backup output