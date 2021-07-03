#!/bin/bash
clear

hn=$(hostname)

bk_path="/mnt/pdata/hitachi/vps/proxmox/"

echo "Restore node and cluster configuration"
echo "Current hostname is : $hn"
echo "If different then the one in backup please change it to the one from backup"
echo "Steps to restore:"
echo " - Re-install the node"
echo "  - Re-install. Make sure the hostname is the same as it was before you continue. "
echo "  - Activate license again if you have any."
echo "  - Install updates, to get the same patchlevel as the other nodes."

sleep 3

read -rp "Are you sure you want to RESTORE the node from backup? (Y/n) " yes_no
  case "$yes_no" in
      [Yy]*|"")

        read -p "Enter the folder name for the node backup (ex. node-proxmox-01-10-2021 ):" bk_dir
        read -p "You entered $bk_dir . Is this correct?" confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
        


        echp "Restore /etc/hosts/"

        #cp  /etc/hosts      
exit 0;;

      [Nn]*) echo "Services NOT stopped! Backup not started!"
      exit 0;;
  esac