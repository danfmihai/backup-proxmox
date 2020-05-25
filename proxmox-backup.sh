#!/bin/bash

BACKUP_PATH="/var/tmp/"
BACKUP_FILE="pve-host"
KEEP_DAYS=7
PVE_BACKUP_SET="/etc/pve/ /etc/lvm/ /etc/modprobe.d/ /etc/network/interfaces /etc/vzdump.conf /etc/sysctl.conf /etc/resolv.conf /etc/ksmtuned.conf /etc/hosts /etc/hostname /etc/cron* /etc/aliases"
PVE_CUSTOM_BACKUP_SET="/var/lib/pve-cluster/ /root/" # /etc/apcupsd/ /etc/multipath/ /etc/multipath.conf

tar -czf $BACKUP_PATH$BACKUP_FILE-$(date +%Y_%m_%d-%H_%M_%S).tar.gz --absolute-names $PVE_BACKUP_SET $PVE_CUSTOM_BACKUP_SET
find $BACKUP_PATH$BACKUP_FILE-* -mindepth 0 -maxdepth 0 -depth -mtime +$KEEP_DAYS -delete