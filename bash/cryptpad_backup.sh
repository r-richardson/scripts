#!/bin/bash
# This script helps you backup important files of a Cryptpad instance.
# Variables can be defined in the cryptpad_backup.conf or passed as arguments.
# Command line arguments will override the values in cryptpad_backup.conf.
table=( "┌────────────┬──────────┬──────────────────────────────┐"
        "├────────────┼──────────┼──────────────────────────────┴"
        "├~~~~~~~~~~~~┼~~~~~~~~~~┼~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        "├────────────┼──────────┼──────────────────────────────┬"
        "└────────────┴──────────┴──────────────────────────────┘"
      )
#───────────────────────────
# SCRIPT
print_help() {
  echo "Cryptpad Backup Script Help"
  echo "============================"
  echo "This script helps you to backup important files of a Cryptpad instance."
  echo "It uses SCP for transfer, then compresses them into a .tar.gz archive."
  echo ""
  echo "Usage:"
  echo "  ./cryptpad_backup.sh -i <ip_address> [options]"
  echo ""
  echo "Options:"
  echo "  -i <ip_address>   Set Cryptpad IP address   (server, set here or within script)"
  echo "  -c <path>         Set Cryptpad path         (server, default: ~/cryptpad)"
  echo "  -b <path>         Set backup directory      (client, default: ~/.backup/cryptpad)"
  echo "  -p <port>         Set target ssh port               (default = 22)"
  echo "  -u <username>     Set ssh username                  (default = username of client)"
  echo "  -h                Display this help page"
  echo ""
  echo "Example:"
  echo "  ./cryptpad_backup.sh -i 192.168.2.100 -c /opt/cryptpad -b /home/user/backups"
  echo ""
  echo "For more information, refer to the README.md file."
}

backup() {
  file_path=$(migrate_path "$1")
  parent_dir=${file_path%/*}

  mkdir -p $temp_backup_dir$parent_dir
  scp -rpq -P ${ssh_port} ${ssh_username}@${cryptpad_ip}:$file_path $temp_backup_dir$file_path
  ret=$? && check_success $ret "fetched" "couldn't fetch" $file_path
}

check_success() {
  if [ $1 -eq 0 ]; then
    echo "│ $(date +%F) │ $(date +%H-%M-%S) │ $2: $4"
    echo "$(date +%F)/$(date +%H-%M-%S): $2: $4" >> $backup_log_full_path
  else
    echo -e "│ $(date +%F) │ $(date +%H-%M-%S) │ ${FAILURE_COLOR}$3${NO_COLOR}: $4 returned $1"
    echo "$(date +%F)/$(date +%H-%M-%S): $3: $4 returned $1" >> $backup_log_full_path
    no_failures=0
    return 1
  fi
}

migrate_path() {
  local value=$1
  value=${value%/}
  if [[ "$value" != /* ]]; then # if path is relative,
      value="${cryptpad_path}/${value}" # make absolute
  fi
  echo "$value"
}

get_filepath_from_config() {
    local config="$1"
    local var_name="$2"
    # extract value
    local path=$(grep "$var_name" "$config" | sed -n 's/^.*: *'\''\(.*\)'\'' *,/\1/p' | tr -d "'")
    path=$(migrate_path "$path")
    echo "$path"
}

handle_signal() {
    echo "Interrupt received. Stopping CryptPad Backup..."
    exit 1
}
trap handle_signal SIGINT

config_locations=(
    "/home/$(id -u -n)/.config/cryptpad_backup/cryptpad_backup.conf"
    "$(pwd)/cryptpad_backup.conf"
    # Add additional locations here if needed in the future
)

# Check and load variables from cryptpad_backup.conf
for config in "${config_locations[@]}"; do
    if [[ -f "$config" ]]; then
        echo "Loading variables from $config"
        source "$config"
        break
    fi
done

# Process command-line options
while getopts "i:c:b:p:u:" opt; do
    case "$opt" in
    i) cryptpad_ip="$OPTARG" ;;
    c) cryptpad_path="$OPTARG" ;;
    b) backup_dir="$OPTARG" ;;
    p) ssh_port="$OPTARG" ;;
    u) ssh_username="$OPTARG" ;;
    \?) print_help
        exit 1 ;;
    esac
done

# Check if all mandatory variables are set
mandatory_vars=("cryptpad_ip")
missing_vars=()
for var in "${mandatory_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        missing_vars+=("$var")
    fi
done

version=1.1; TZ='Europe/Berlin'; start_datetime=$(date +%F_%H-%M-%S)
SUCCESS_COLOR='\033[0;32m'; FAILURE_COLOR='\033[0;31m'; NO_COLOR='\033[0m'
[ -z ${cryptpad_ip} ] &&
echo "$cryptpad_ip" &&
echo -e "${FAILURE_COLOR}NO CRYPTPAD IP PROVIDED${NO_COLOR}" && print_help && exit 0;

[ -z ${cryptpad_path} ] && cryptpad_path="/home/$(id -u -n)/cryptpad"
[ -z ${backup_dir} ] && backup_dir="/home/$(id -u -n)/.Backup/cryptpad"
[ -z ${ssh_username} ] && ssh_username=$(id -u -n)
[ -z ${ssh_port} ] && ssh_port=22
[ -z ${archive_name} ] && archive_name="cryptpad_backup_${start_datetime}.tar.gz"
[ -z ${log_name} ] && log_name='.cryptpad_backup.log'

[ ! -d ${backup_dir} ] &&
mkdir -p ${backup_dir}
backup_log_full_path="${backup_dir}/${log_name}"
[ ! -f ${backup_log_full_path} ] &&
touch $backup_log_full_path

echo ${table[0]}
start_msg="CRYPTPAD BACKUP v$version STARTED"
echo "│ $(date +%F) │ $(date +%H-%M-%S) │ $start_msg │"
echo "$(date +%F)/$(date +%H-%M-%S): $start_msg" >> $backup_log_full_path
echo ${table[1]}

cryptpad_config="${cryptpad_path}/config/config.js"
temp_backup_dir="${backup_dir}/${start_datetime}"
no_failures=1
backup $cryptpad_config
backup $(get_filepath_from_config "$temp_backup_dir$cryptpad_config" "filePath")
backup $(get_filepath_from_config "$temp_backup_dir$cryptpad_config" "archivePath")
backup $(get_filepath_from_config "$temp_backup_dir$cryptpad_config" "pinPath")
backup $(get_filepath_from_config "$temp_backup_dir$cryptpad_config" "taskPath")
backup $(get_filepath_from_config "$temp_backup_dir$cryptpad_config" "blockPath")
backup $(get_filepath_from_config "$temp_backup_dir$cryptpad_config" "blobPath")
backup $(get_filepath_from_config "$temp_backup_dir$cryptpad_config" "blobStagingPath")
backup $(get_filepath_from_config "$temp_backup_dir$cryptpad_config" "decreePath")
backup $(get_filepath_from_config "$temp_backup_dir$cryptpad_config" "logPath")
for path in "${paths[@]}"; do
    backup "$path"
done
#───────────────────────────
# COMPRESSION:
if [ "$no_failures" -eq 1 ]; then
  echo ${table[2]}
  echo "│ $(date +%F) │ $(date +%H-%M-%S) │ compressing files now..."
  echo "$(date +%F)/$(date +%H-%M-%S): compressing files" >> $backup_log_full_path
  cd $temp_backup_dir > /dev/null &&
  tar -czf ${backup_dir}/${archive_name} .
  ret=$? && check_success $ret "created archive" "compression FAILURE" "${backup_dir}/${archive_name}" &&
  cd - > /dev/null &&
  rm -rf $temp_backup_dir
else
  compr_skip_msg="skipping compression due to previous errors!"
  echo "│ $(date +%F) │ $(date +%H-%M-%S) │ $compr_skip_msg"
  echo "$(date +%F)/$(date +%H-%M-%S): $compr_skip_msg" >> $backup_log_full_path
fi

echo ${table[2]}
echo "│ $(date +%F) │ $(date +%H-%M-%S) │ log saved to: ${backup_dir}/${log_name}"
echo ${table[3]}

if [ "$no_failures" -eq 1 ]; then
    echo -e "│ $(date +%F) │ $(date +%H-%M-%S) │ ${SUCCESS_COLOR} BACKUP SUCCESSFUL ${NO_COLOR} │"
    echo "$(date +%F)/$(date +%H-%M-%S): CRYPTPAD BACKUP SUCCESSFUL" >> $backup_log_full_path
else
    echo -e "│ $(date +%F) │ $(date +%H-%M-%S) │ ${FAILURE_COLOR} BACKUP FAILURE!  ${NO_COLOR} │"
    echo "$(date +%F)/$(date +%H-%M-%S): CRYPTPAD BACKUP FAILURE!" >> $backup_log_full_path
fi
echo ${table[4]}
