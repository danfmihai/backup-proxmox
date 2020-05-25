#!/bin/bash
# Version	      0.2.2 - BETA ! !
# Date		      02.20.2020
# Author 	      DerDanilo 
# Contributors    aboutte, xmirakulix, bootsie123
clear
# set vars

# always exit on error
set -e

# permanent backups directory
# default value can be overridden by setting environment variable before running prox_config_backup.sh
# example: export BACKUP_DIR="/mnt/pve/media/backup
_bdir=${BACK_DIR:-/mnt/backup/vps/proxmox/backup-proxmox}

# number of backups to keep before overriding the oldest one
MAX_BACKUPS=5

# temporary storage directory
_tdir=${TMP_DIR:-/var/tmp}

_tdir=$(mktemp -d $_tdir/proxmox-XXXXXXXX)
#_tdir=$(mkdir -p $_tdir/proxmox-"$_HOSTNAME")

clean_up () {
    echo "Cleaning up"
    rm -rf $_tdir
}

# register the cleanup function to be called on the EXIT signal
trap clean_up EXIT

# Don't change if not required
_now=$(date +%Y-%m-%d.%H.%M.%S)
_HOSTNAME=$(hostname -f)
_filename1="$_tdir/proxmoxetc.$_now.tar"
_filename2="$_tdir/proxmoxpve.$_now.tar"
_filename3="$_tdir/proxmoxroot.$_now.tar"
_filename4="$_tdir/proxmox_backup_"$_HOSTNAME"_"$_now".tar.gz"
_restore1="$_bdir/proxmoxetc.*"
_restore2="$_bdir/proxmoxpve.*"
_restore3="$_bdir/proxmoxroot.*"


##########

  description () {
    clear
    cat <<EOF

        Proxmox Server Config Backup
        Hostname: "$_HOSTNAME"
        Timestamp: "$_now"

        Files to be saved:
        "/etc/*, /var/lib/pve-cluster/*, /root/*"

        Backup target:
        "$_bdir"
        -----------------------------------------------------------------

        This script is supposed to backup your node config and not VM
        or LXC container data. To backup your instances please use the
        built in backup feature or a backup solution that runs within
        your instances.

        For questions or suggestions please contact me at
        https://github.com/DerDanilo/proxmox-stuff
        -----------------------------------------------------------------

        Hit return to proceed or CTRL-C to abort.

EOF
    read dummy
    clear
}

  are_we_root_abort_if_not () {
    if [[ ${EUID} -ne 0 ]] ; then
      echo "Aborting because you are not root" ; exit 1
    fi
}

  check_num_backups () {
    if [[ $(ls ${_bdir} -l | grep ^- | wc -l) -ge $MAX_BACKUPS ]]; then
      local oldbackup="$(ls ${_bdir} -t | tail -1)"
      echo "${_bdir}/${oldbackup}"
      rm "${_bdir}/${oldbackup}"
    fi
}

  get_latest_backup () {
    if [[ $(ls ${_bdir} -t | sort | tail -1 | wc -l) >= 1 ]]; then
        echo "Latest backup found : $(ls ${_bdir} -t | sort | tail -1)"
        _restore4=$(ls ${_bdir} -t | sort | tail -1)
    fi    
}


  copyfilesystem () {
    echo "Tar files"
    # copy key system files
    tar --warning='no-file-ignored' -cvPf "$_filename1" /etc/.
    tar --warning='no-file-ignored' -cvPf "$_filename2" /var/lib/pve-cluster/.
    tar --warning='no-file-ignored' -cvPf "$_filename3" /root/.
}

  compressandarchive () {
    echo "Compressing files"
    # archive the copied system files
    tar -cvzPf "$_filename4" $_tdir/*.tar

    # copy config archive to backup folder
    # this may be replaced by scp command to place in remote location
    cp $_filename4 $_bdir/
}

  unpackarchive () {
    echo "Unpacking backup ..."
    tar -zxvf $_restore4
    echo "Unpacking contents ..."
    tar -xvf $_restore1
    tar -xvf $_restore2
    tar -xvf $_restore3
    $(ls -l ${_tdir})
}

  stopservices () {
    # stop host services
    for i in pve-cluster pvedaemon vz qemu-server; do systemctl stop $i ; done
    # give them a moment to finish
    sleep 10s
}

  startservices () {
    # restart services
    for i in qemu-server vz pvedaemon pve-cluster; do systemctl start $i ; done
    # Make sure that all VMs + LXC containers are running
    qm startall
}

##########

echo 
echo "1. Backup PROXMOX"
echo "2. Restore PROXMOX"
echo "To exit press any key"
read -r -p "Please choose: [1],[2] or exit  " input

case $input in
    [1])
    echo "Backing up...";
    description
    are_we_root_abort_if_not
    check_num_backups        
    # We don't need to stop services, but you can do that if you wish
    #stopservices
    copyfilesystem
    # We don't need to start services if we did not stop them
    #startservices
    compressandarchive
	 ;;
    [2])
      get_latest_backup
      if [ -f $_restore4 ]; then
        echo "Restoring ...${_restore4}"
        are_we_root_abort_if_not
        cp -avr $_restore4 $_tdir
        # unpack backup
        cd $_tdir
        $(ls -l)
        unpackarchive
        stopservices
      else 
        echo "No backup found"
        ls ${_bdir} -l
      fi
       ;;
    *)
 echo "EXIT"
 exit 1
 ;;
esac
