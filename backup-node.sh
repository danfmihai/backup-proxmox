#!/bin/bash
clear
hn=$(hostname)
bk_dir="/root/node-$hn-$(date '+%m-%d-%Y')"
echo "This script will create a backup of the Proxmox Node.\\n"

 if [ ! -d  $bk_dir ] 
 then
           mkdir $bk_dir
 fi

echo "Backup folder is $bk_dir"       

sleep 3 

echo "Preparing the node for backup:\\n\n"

read -rp "Are you sure you want to STOP the services and start the backup? (Y/n) " yes_no
  case "$yes_no" in
      [Yy]*|"")
        echo "Stopping the following services:"
        echo "pvestatd.service"
        echo "pvedaemon.service"
        echo "pve-cluster.service"

        systemctl stop pvestatd.service
        systemctl stop pvedaemon.service
        systemctl stop pve-cluster.service

        echo "Backup node and cluster configuration:"

        tar czfP $bk_dir/pve-cluster-backup.tar.gz /var/lib/pve-cluster

        # echo "Backup /root/.ssh/ , there are two symlinks here to the shared pve config authorized_keys and authorized_keys.orig, don't worry about these two yet as they're stored in /var/lib/pve-cluster/"        
        
        tar czfP $bk_dir/ssh-backup.tar.gz /root/.ssh

        echo "Backup /etc/corosync/"

        tar czfP $bk_dir/corosync-backup.tar.gz /etc/corosync

        echo "Backup /etc/hosts/"

        cp /etc/hosts $bk_dir

        echo "Backup /etc/network/interfaces"

        cp /etc/network/interfaces $bk_dir
        
        echo "\\n"
        echo "Backup files created!\n"
        
        rsync -a $bk_dir /mnt/backup/vps/proxmox
        
        echo "Backup copied to /mnt/backup/vps/proxmox\\n"
                
        systemctl start pvestatd.service
        systemctl start pvedaemon.service
        systemctl start pve-cluster.service
        systemctl start pve-cluster.service

        echo "Backup complete! Services restarted.\n"

        echo "For more info go to:"
        echo "https://pve.proxmox.com/wiki/Proxmox_VE_4.x_Cluster#Re-installing_a_cluster_node\n"
        exit 0;;

      [Nn]*) echo "Services NOT stopped! Backup not started!"
      exit 0;;
  esac
