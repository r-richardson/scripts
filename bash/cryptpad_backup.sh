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
  echo "It uses scp for transfer, then compresses them into a .tar.gz archive."
  echo "Make sure your backup client has ssh access to your cryptpad files."
  echo ""
  echo "Usage:"
  echo "  ./cryptpad_backup.sh -i <ip_address> [options]"
  echo ""
  echo "Options:"
  echo "  -i <ip_address>   Cryptpad server IP address    (server, set here or within script)"
  echo "  -c <path>         Cryptpad installation path    (server, default: ~/cryptpad)"
  echo "  -u <username>     SSH username                  (server, default = username of client)"
  echo "  -p <port>         Target SSH port               (server, default = 22)"
  echo "  -b <path>         Backup base directory         (client, default: ~/.backup/cryptpad)"
  echo "  -k <path>         SSH private key path          (client, default: ~/.ssh/id_ed25519)"
  echo "  -e <password>     Archive encryption password   (client, default = \"\" -> no encryption)"
  echo "  -s <filesize>     Max archive part size         (client, default = 0 -> do not split)"
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
  scp -rpq -P $ssh_port -i $ssh_privkey_path ${ssh_username}@${cryptpad_ip}:$file_path $temp_backup_dir$file_path
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
    # Replace "/./" with "/"
    path=$(echo "$path" | sed 's|^./||')
    echo "$path"
}

debug_log() {
    if [ "$debug" = true ]; then
        local prefix=""
        local variables=()

        # Determine behavior based on argument count
        if [ $# -eq 0 ] || [ $# -eq 1 ]; then
            # No parameters or one parameter: log all relevant variables
            variables=("cryptpad_ip" "cryptpad_path" "backup_dir" "ssh_privkey_path" "ssh_username" "ssh_port")
            prefix="$1"
        else
            # Two or more parameters: use the first as prefix, rest as specific variables
            prefix="$1"
            shift 
            variables=("$@")
        fi

        for var in "${variables[@]}"; do
            if [ -n "${prefix}" ]; then
                echo "${prefix}: ${var}=${!var}"
                echo "${prefix}: ${var}=${!var}" >> $backup_log_full_path
            else
                echo "${var}=${!var}"
                echo "${var}=${!var}" >> $backup_log_full_path
            fi
        done
    fi
}

handle_signal() { 
    echo "Interrupt received. Deleting cached files, exiting CryptPad Backup Script..." | tee -a $backup_log_full_path
    [ -d $temp_backup_dir ] && rm -rf $temp_backup_dir 
    [ -d $backup_dir/$archive_name ] && rm -rf $backup_dir/$archive_name 
    exit 1
}
trap handle_signal SIGINT

config_locations=(
    "/home/$(id -u -n)/.config/cryptpad_backup/cryptpad_backup.conf"
    "$(pwd)/cryptpad_backup.conf"
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
while getopts "i:c:u:p:b:k:e:s:" opt; do
    case "$opt" in
    i) cryptpad_ip="$OPTARG" ;;
    c) cryptpad_path="$OPTARG" ;;
    u) ssh_username="$OPTARG" ;;
    p) ssh_port="$OPTARG" ;;
    b) backup_dir="$OPTARG" ;;
    k) ssh_privkey_path="$OPTARG" ;;
    e) encryption_password="$OPTARG" ;;
    s) split_archive_size="$OPTARG" ;;
    \?) print_help
        exit 1 ;;
    esac
done

version=1.1; TZ='Europe/Berlin'; start_datetime=$(date +%F_%H-%M-%S)
SUCCESS_COLOR='\033[0;32m'; FAILURE_COLOR='\033[0;31m'; NO_COLOR='\033[0m'
[ -z ${cryptpad_ip} ] &&
echo "$cryptpad_ip" &&
echo -e "${FAILURE_COLOR}NO CRYPTPAD IP PROVIDED${NO_COLOR}" && print_help && exit 0;

# defaults
[ -z ${cryptpad_path} ] && cryptpad_path="/home/$(id -u -n)/cryptpad"
[ -z ${ssh_username} ] && ssh_username=$(id -u -n)
[ -z ${ssh_port} ] && ssh_port=22
[ -z ${backup_dir} ] && backup_dir="/home/$(id -u -n)/Backup/cryptpad"
[ -z ${ssh_privkey_path} ] && ssh_privkey_path="/home/$(id -u -n)/.ssh/id_ed25519"
[ -z ${encryption_password} ] && encryption_password=""
[ -z ${archive_name} ] && archive_name="cryptpad_backup_${start_datetime}"
[ -z ${log_name} ] && log_name='.cryptpad_backup.log'

[ ! -d ${backup_dir} ] &&
mkdir -p ${backup_dir}
backup_log_full_path="${backup_dir}/${log_name}"
[ ! -f ${backup_log_full_path} ] &&
touch $backup_log_full_path

newest_backup=$(ls -t $backup_dir/*.{tar.gz,tar.gz.enc} 2>/dev/null | head -n 1)
oldest_backup=$(ls -tr $backup_dir/*.{tar.gz,tar.gz.enc} 2>/dev/null | head -n 1)

# alternative
# newest_backup=$(find $backup_dir -name "*.tar.gz" -type f -printf "%T+ %p\n" | sort -r | head -n 1 | cut -d' ' -f2-)
# oldest_backup=$(find $backup_dir -name "*.tar.gz" -type f -printf "%T+ %p\n" | sort | head -n 1 | cut -d' ' -f2-)

last_backup_size=$(du -s "$newest_backup" | cut -f1)
available_space=$(df "$backup_dir" | tail -1 | awk '{print $4}')
required_space=$((last_backup_size * 2)) # TODO add to backup config, allow either multiplier or total size to be set

# Checks disk space and deletes old backups until required_space is available
while [[ $available_space -lt $required_space ]] && ls $backup_dir/*.{tar.gz,tar.gz.enc} 2>/dev/null 1> /dev/null; do
    backup_count=$(ls $backup_dir/*.{tar.gz,tar.gz.enc} 2>/dev/null | wc -l) 

    if [[ $backup_count -gt 1 ]]; then
        oldest_backup=$(ls -tr $backup_dir/*.{tar.gz,tar.gz.enc} 2>/dev/null | head -n 1)
        rm -f "$oldest_backup"
    else
        break
    fi
    available_space=$(df "$backup_dir" | tail -1 | awk '{print $4}')
done

# checking if enough time has passed since the last successful backup
if ! find "$backup_dir" -type f \( -name '*.tar.gz' -o -name '*.tar.gz.enc' \) -mtime -${min_days_between_backups:-0} | grep -q .; then
  echo ${table[0]}
  start_msg="CRYPTPAD BACKUP v$version STARTED"
  echo "│ $(date +%F) │ $(date +%H-%M-%S) │ $start_msg │"
  echo "$(date +%F)/$(date +%H-%M-%S): $start_msg" >> $backup_log_full_path
  echo ${table[1]}

  cryptpad_config="${cryptpad_path}/config/config.js"
  temp_backup_dir="${backup_dir}/${start_datetime}"
  no_failures=1
  declare -a cryptpad_config_keys=("filePath" "archivePath" "pinPath" "taskPath" "blockPath" "blobPath" "blobStagingPath" "decreePath" "logPath")

  backup "$cryptpad_config"

  # Iterate over the array of cryptpads config "Database" keys
  for key in "${cryptpad_config_keys[@]}"; do
      backup_path=$(get_filepath_from_config "$temp_backup_dir$cryptpad_config" "$key")
    
      if [[ "$backup_path" != "" && "$backup_path" != "false" && "$backup_path" != "False" ]]; then
          backup "$backup_path"
      fi
  done

  for backup_custom_path in "${custom_paths[@]}"; do # sourced from backup config
      backup "$backup_custom_path"
  done
  #───────────────────────────
  #
  # COMPRESSION:
if [ "$no_failures" -eq 1 ]; then
    echo ${table[2]}
    echo "│ $(date +%F) │ $(date +%H-%M-%S) │ compressing files now..."
    echo "$(date +%F)/$(date +%H-%M-%S): compressing files" >> $backup_log_full_path
    cd $temp_backup_dir > /dev/null &&

    if [[ $encryption_password != "" ]]; then
        archive_name=${archive_name}.tar.gz.enc
        if [[ -n $split_archive_size ]]; then
            tar -czf - . | openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:${encryption_password} | split -b $split_archive_size - ${backup_dir}/${archive_name}
        else
            tar -czf - . | openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:${encryption_password} -out ${backup_dir}/${archive_name}
        fi
    else
        archive_name=${archive_name}.tar.gz
        if [[ -n $split_archive_size ]]; then
            tar -czf - . | split -b $split_archive_size - ${backup_dir}/${archive_name}
        else
            tar -czf ${backup_dir}/${archive_name} . 
        fi
    fi
    ret=${PIPESTATUS[0]} # should work

    check_success $ret "created and compressed archive" "compression or encryption FAILURE" "${backup_dir}/${archive_name}"

    cd - > /dev/null
  else
    compr_skip_msg="skipping compression due to previous errors!"
    echo "│ $(date +%F) │ $(date +%H-%M-%S) │ $compr_skip_msg"
    echo "$(date +%F)/$(date +%H-%M-%S): $compr_skip_msg" >> $backup_log_full_path
  fi

  [ -d $temp_backup_dir ] && rm -rf $temp_backup_dir 
  [ -d $backup_dir/$archive_name ] && rm -rf $backup_dir/$archive_name 

  echo ${table[2]}
  echo "│ $(date +%F) │ $(date +%H-%M-%S) │ log saved to: ${backup_dir}/${log_name}"
  echo ${table[3]}

  if [ "$no_failures" -eq 1 ]; then
      echo -e "│ $(date +%F) │ $(date +%H-%M-%S) │     ${SUCCESS_COLOR} BACKUP SUCCESSFUL ${NO_COLOR}      │"
      echo "$(date +%F)/$(date +%H-%M-%S): BACKUP SUCCESSFUL" >> $backup_log_full_path
  else
      echo -e "│ $(date +%F) │ $(date +%H-%M-%S) │      ${FAILURE_COLOR} BACKUP FAILURE! ${NO_COLOR}       │"
      echo "$(date +%F)/$(date +%H-%M-%S): BACKUP FAILURE!" >> $backup_log_full_path
  fi
  echo ${table[4]}
else
  echo "Not backing up CryptPad yet!"
  echo "Newest archive: $newest_backup"
  echo "Minimum Days between Backups: ${min_days_between_backups:-0}"
fi
