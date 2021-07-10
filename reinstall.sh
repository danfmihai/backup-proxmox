#!/bin/bash
clear

hn=$(hostname)
step1=/root/step1
step2=/root/step2
bk_path="/mnt/pdata/hitachi/vps/proxmox/"


echo "Restore node and cluster configuration"
echo "Current hostname is : $hn"
# echo "If different then the one in backup please change it to the one from backup"
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
        
      ## Checking if backup folder exists
      if [ ! -d  $bk_path/$bk_dir ] 
      then
           echo "Folder $bk_dir not found!"
           echo "Will try to import existing zfs pools and reboot!"
           zpool import -f ironwolf
           zpool import -f hitachi
           echo "Reboot...Please run the script again after reboot!"
           sleep (3)
           reboot
           exit 0;;     
      else
          # Starting the restore
        cd $bk_path/$bk_dir
        if [ ! -f $step1 ]
         then
         echo "Restoring /etc/hosts/"
         cp -v hosts /etc/hosts
         echo "Restoring /etc/network/interfaces"
         cp -v interfaces /etc/network/interfaces
         touch $step1
         reboot
         else
          if [ ! -f $step2 ]
          then            
          echo "Stopping services and restoring .ssh corosync and pve-cluster:"
          systemctl stop pvestatd.service 
          systemctl stop pvedaemon.service
          systemctl stop pve-cluster.service  
          cp ssh-backup.tar.gz /root/
          cp corosync-backup.tar.gz /root/
          cp pve-cluster-backup.tar.gz /root/
          cp etc-tar.gz /root/
          cd / ; tar -xzf /root/ssh-backup.tar.gz
          rm -rf /var/lib/pve-cluster
          cd / ; tar -xzf /root/pve-cluster-backup.tar.gz
          rm -rf /etc/corosync
          cd / ; tar -xzf /root/corosync-backup.tar.gz 
          cd / ; tar -xzf /root/etc-tar.gz  
          echo "Copying /etc/apt folder"
          rm -rf /etc/apt
          cp -v /root/etc/apt /etc 
          echo "Copying /etc/default/grub file and the /etc/modules"
          cp -v /root/etc/default/grub /etc/default/
          cp -v /root/etc/modules /etc/modules

          echo "Mounting nvme drive permanently in /etc/fstab"
          lsblk | grep nvme0n1p1
          cp /etc/fstab /etc/fstab.old
          blkid | grep nvme0n1p1 >> /etc/fstab
          nano /etc/fstab
          
          systemctl start pve-cluster.service
          ln -sf /etc/pve/priv/authorized_keys /root/.ssh/authorized_keys
          ln -sf /etc/pve/priv/authorized_keys /root/.ssh/authorized_keys.orig
          systemctl start pvestatd.service
          systemctl start pvedaemon.service
          echo ".ssh corosync and pve-cluster restored!"
          echo "Restoring grub file:"
          touch $step2
          
          echo "Installing programs nfs glances git"
          apt install -y glances nfs-kernel-server git
          cp -v /root/etc/exports /etc/

          fi


      fi 
              
exit 0;;

      [Nn]*) echo "Services NOT stopped! Backup not started!"
      exit 0;;
  esac