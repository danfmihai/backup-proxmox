# backup-proxmox
backup proxmox script

Proxmox PVE Host Config Backup Script
This script can be used to backup essential configuration files from the Proxmox Virtual Enivronment (PVE) host.

The script will create backups using tar with specified backup prefix and date and time stamp in the file name. Script will also delete backups that are older then number of days specified.

Create backup script file
To create backup script that will be executed every day we can create backup script in /etc/cron.daily/ folder. We need to make it writeable by root (creator) only, but readable and executable by everyone:

touch /etc/cron.daily/pvehost-backup
chmod 755 /etc/cron.daily/pvehost-backup
Copy and paste following script into the created file (e.g. using vim.tiny):

#!/bin/sh
BACKUP_PATH="/var/tmp/"
BACKUP_FILE="pve-host"
KEEP_DAYS=7
PVE_BACKUP_SET="/etc/pve/ /etc/lvm/ /etc/modprobe.d/ /etc/network/interfaces /etc/vzdump.conf /etc/sysctl.conf /etc/resolv.conf /etc/ksmtuned.conf /etc/hosts /etc/hostname /etc/cron* /etc/aliases"
PVE_CUSTOM_BACKUP_SET="/etc/apcupsd/ /etc/multipath/ /etc/multipath.conf"

tar -czf $BACKUP_PATH$BACKUP_FILE-$(date +%Y_%m_%d-%H_%M_%S).tar.gz --absolute-names $PVE_BACKUP_SET $PVE_CUSTOM_BACKUP_SET
find $BACKUP_PATH$BACKUP_FILE-* -mindepth 0 -maxdepth 0 -depth -mtime +$KEEP_DAYS -delete
Note: Please modify the PVE_CUSTOM_BACKUP_SET variable to fit your PVE host needs. You can leave it as empty string ("") if no host specific configuration is needed.

Don't forget to change path where to store backups, the best way is to store backups outside physical host, e.g. on attached NAS storage.

Modify variables
You can modify variables to fit backups for your individual hosts:

BACKUP_PATH to specifiy where to store backups,
BACKUP_FILE to specify backups file prefix,
KEEP_DAYS to specify how many old backups to keep (in days)
PVE_CUSTOM_BACKUP_SET to add your installation specific folders and/or files,
PVE_BACKUP_SET defines standard set of folders and config files for generic PVE host.
