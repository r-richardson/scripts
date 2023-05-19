#!/bin/bash
#─────────────────
function print_help {
  echo "Cryptpad Backup Script Help"
  echo "============================"
  echo "This script helps you to backup important files of a Cryptpad instance."
  echo "It uses SCP to transfer the files and compresses them into a .tar.gz archive."
  echo ""
  echo "Usage:"
  echo "  ./cryptpad_backup.sh [options]"
  echo ""
  echo "Options:"
  echo "  -i <ip_address>   Set the Cryptpad instance IP address (overrides cryptpad_ip variable)"
  echo "  -c <path>         Set the Cryptpad path on the remote server (overrides cryptpad_path variable)"
  echo "  -b <path>         Set the backup directory on the local machine (overrides backups_dir variable)"
  echo "  -h                Display this help page"
  echo ""
  echo "Example:"
  echo "  ./cryptpad_backup.sh -i 192.168.2.100 -c /opt/cryptpad -b /home/user/backups"
  echo ""
  echo "For more information, refer to the README.md file."
}

# SETUP:
version=1.0; TZ='Europe/Berlin'
start_datetime=$(date +%F_%H-%M-%S)

# LOCAL MACHINE SETTINGS:
backups_dir="/home/$(id -u -n)/.backup/cryptpad"
backup_archive_name="cryptpad_backup_${start_datetime}.tar.gz"
backups_log_name='.cryptpad_backup.log'

# CRYPTPAD HOST SETTINGS:
ssh_username=$(id -u -n)                        # <- change if needed
cryptpad_ip='x.x.x.x'                           # <- CHANGE THIS
cryptpad_path="/path/to/cryptpad/installation"  # <- CHANGE THIS

while getopts i:c:b: flag # get input parameters
do
    case "${flag}" in
        i) cryptpad_ip=${OPTARG};;   # override
        c) cryptpad_path=${OPTARG};; # override
        b) backups_dir=${OPTARG};;   # override
        ?) print_help; exit 0 ;;
    esac
done
cryptpad_path=${cryptpad_path%/}
backups_dir=${backups_dir%/}

# ASSET LOCATIONS                               # <- change if needed
cryptpad_config="${cryptpad_path}/config/config.js"
datastore_path="${cryptpad_path}/datastore"
block_path="${cryptpad_path}/block"
blob_path="${cryptpad_path}/blob"
blobstage_path="${cryptpad_path}/data/blobstage"
archive_path="${cryptpad_path}/data/archive"
pins_path="${cryptpad_path}/data/pins"
tasks_path="${cryptpad_path}/data/tasks"
decrees_path="${cryptpad_path}/data/decrees"
logs_path="${cryptpad_path}/data/logs"
customize_path="${cryptpad_path}/customize"
systemd_service="/etc/systemd/system/cryptpad.service"
nginx_config="/etc/nginx/conf.d/cryptpad.conf"

#────────────────────
# SCRIPT:
temp_backup_dir="${backups_dir}/${start_datetime}/"
backup_log_full_path="${backups_dir}/${backups_log_name}"

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
table_top='┌────────────┬──────────┬──────────────────────────────┐'
table_top2='├────────────┼──────────┼──────────────────────────────┴'
table_seperator='├~~~~~~~~~~~~┼~~~~~~~~~~┼~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
table_bottom2='├────────────┼──────────┼──────────────────────────────┬'
table_bottom='└────────────┴──────────┴──────────────────────────────┘'

if [ $cryptpad_ip == "x.x.x.x" ]; then echo -e "${RED}NO CRYPTPAD IP PROVIDED${NC}"
print_help; exit 0; fi

if [ $cryptpad_path == "/path/to/cryptpad/installation" ]; then echo -e "${RED}NO CRYPTPAD PATH PROVIDED${NC}"
print_help; exit 0; fi

# log setup
[ ! -d ${backups_dir} ] &&
mkdir -p ${backups_dir}

[ ! -f ${backup_log_full_path} ] &&
touch $backup_log_full_path

declare -i backup_health=0
something_worked=false

function checkSuccess {
  if [ $1 -eq 0 ]; then
    echo "│ $(date +%F) │ $(date +%H-%M-%S) │ $2: $4"
    echo "$(date +%F)/$(date +%H-%M-%S): $2: $4" >> $backup_log_full_path
    something_worked=true
  else
    echo -e "│ $(date +%F) │ $(date +%H-%M-%S) │ ${RED}$3${NC}: $4 returned $1"
    echo "$(date +%F)/$(date +%H-%M-%S): $3: $4 returned $1" >> $backup_log_full_path
    backup_health+=1
    return 1
  fi
}

function backup {
  file_path=$1
  parent_dir=${file_path%/*}
  mkdir -p $temp_backup_dir./$parent_dir
  scp -rpq ${ssh_username}@${cryptpad_ip}:$file_path ${temp_backup_dir}./$file_path
  ret=$?
  checkSuccess $ret "fetched" "couldn't fetch" $file_path
}

echo $table_top
echo "│ $(date +%F) │ $(date +%H-%M-%S) │ CRYPTPAD BACKUP v$version STARTED │"
echo "$(date +%F)/$(date +%H-%M-%S): CRYPTPAD BACKUP v$version STARTED" >> $backup_log_full_path
echo $table_top2

# BACKUP SCHEDULE:
backup $cryptpad_config
backup $datastore_path
backup $block_path
backup $blob_path
backup $archive_path
backup $pins_path
backup $tasks_path
backup $decrees_path
backup $logs_path
backup $customize_path
backup $systemd_service
backup $nginx_config

#───────────────────────────
# COMPRESSION:
if $something_worked; then
  echo $table_seperator
  echo "│ $(date +%F) │ $(date +%H-%M-%S) │ compressing files now..."
  echo "$(date +%F)/$(date +%H-%M-%S): compressing files" >> $backup_log_full_path
  cd $temp_backup_dir > /dev/null &&
  tar -czf ${backups_dir}/${backup_archive_name} .
  tar_health=$?
  cd - > /dev/null
  checkSuccess $ret "created archive" "compression FAILURE" "\${backups_dir}/${backup_archive_name}"

  if [ $tar_health -eq 0 ]; then
    rm -rf $temp_backup_dir
  else
    echo -e "│ $(date +%F) │ $(date +%H-%M-%S) │ ${RED} compression failure! ${NC} Kept uncompressed files in \${cryptpad_path}/${start_datetime}/"
  fi
fi

echo $table_seperator
echo "│ $(date +%F) │ $(date +%H-%M-%S) │ log saved to: \${backups_path}/${backups_log_name}"
echo $table_bottom2

if [ $backup_health -eq 0 ] && [ $tar_health -eq 0 ]; then
    echo -e "│ $(date +%F) │ $(date +%H-%M-%S) │ ${GREEN} CRYPTPAD BACKUP SUCCESSFUL ${NC} │"
    echo "$(date +%F)/$(date +%H-%M-%S): CRYPTPAD BACKUP SUCCESSFUL" >> $backup_log_full_path
else
    echo -e "│ $(date +%F) │ $(date +%H-%M-%S) │ ${RED}  CRYPTPAD BACKUP FAILURE!  ${NC} │"
    echo "$(date +%F)/$(date +%H-%M-%S): CRYPTPAD BACKUP FAILURE!" >> $backup_log_full_path
fi
echo $table_bottom

