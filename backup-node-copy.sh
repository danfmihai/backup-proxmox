#!/bin/bash
clear

hn=$(hostname)

bk_dir="/mnt/pdata/node-$hn-$(date '+%m-%d-%Y')"

bk_dest="/mnt/pdata/hitachi/vps/proxmox/"

echo "####################################################\n"
echo "This script will create a backup of the Proxmox Node named: $hn.\\n"

 if [ ! -d  $bk_dir ] 
 then
           mkdir -p $bk_dir
 fi

echo "Backup folder is $bk_dir"       

echo "Preparing the node for backup:\\n\n"

read -rp "Are you sure you want to STOP the services and start the backup? (Y/n) " yes_no
  case "$yes_no" in
      [Yy]*|"")
        
	echo "Backup pve VMs and lxc config files from /etc/pve/nodes/"
	echo "Please wait..."

        tar --zstd -cf $bk_dir/etc.tar.zst /etc/pve

	echo "Done. Next..."
	sleep 1
	echo "###############################"
	echo "Stopping the following services:"
        echo "pvestatd.service"
        echo "pvedaemon.service"
        echo "pve-cluster.service"
	echo

        systemctl stop pvestatd.service
        systemctl stop pvedaemon.service
        systemctl stop pve-cluster.service

        echo "Backup node and cluster configuration:"

        tar --zstd -cf $bk_dir/pve-cluster-backup.tar.zst /var/lib/pve-cluster

        # echo "Backup /root/.ssh/ , there are two symlinks here to the shared pve config authorized_keys and authorized_keys.orig, don't worry about these two yet as they're stored in /var/lib/pve-cluster/"        

        tar --zstd -cf $bk_dir/ssh-backup.tar.zst /root/.ssh

        echo "Backup /etc/corosync/"

        tar --zstd -cf $bk_dir/corosync-backup.tar.zst /etc/corosync

        echo "Backup /etc/hosts/"

        cp /etc/hosts $bk_dir

        echo "Backup /etc/network/interfaces"

        cp /etc/network/interfaces $bk_dir

        echo "Backup /root folder"
	echo "Please wait...."
	cd / 
        tar --zstd -cf $bk_dir/root.tar.zst  /root
 	echo 
        echo "Backup files created!\n"
	sleep 1
	
	echo "Copying $bk_dir -> $bk_dest "
	echo "Please wait..."
        #rsync -a $bk_dir /mnt/backup/vps/proxmox

	rsync -a --delete $bk_dir $bk_dest

	echo
        echo "Backup copied to $bk_dest\\n"
	
	sleep 1
		
	echo "#####################################\n"
	echo "Starting  back the following services:\n"
        echo "pvestatd.service"
        echo "pvedaemon.service"
        echo "pve-cluster.service"

        systemctl start pvestatd.service
        systemctl start pvedaemon.service
        systemctl start pve-cluster.service
        systemctl start pve-cluster.service
	echo 
        echo "Backup complete! Services restarted.\n"
	
	echo "All backup files are in $bk_dest!\n"
	
        echo "For more info go to:"
        echo "https://pve.proxmox.com/wiki/Proxmox_VE_4.x_Cluster#Re-installing_a_cluster_node\n"
        exit 0;;

      [Nn]*) echo "Services NOT stopped! Backup not started!"
      exit 0;;
  esac
