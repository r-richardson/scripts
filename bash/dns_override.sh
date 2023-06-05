#!/bin/bash

hosts_file="/etc/hosts"  # Modify this path according to your operating system

add_entry() {
    domain=$1
    ip=$2
    echo "$ip $domain" >> "$hosts_file"  # Append the entry to the host file
}

remove_entry() {
    domain=$1
    sed -i "/$domain/d" "$hosts_file"  # Remove the line containing the specified domain from the host file
}

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <add/remove> <domain> <ip>"
    exit 1
fi

action=$1
domain=$2
ip=$3

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# Check the number of command-line arguments
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <add/remove> <domain> <ip>"
    exit 1
fi

case $action in
    "add")
        add_entry "$domain" "$ip"
        echo "Added entry: $ip $domain"
        ;;
    "remove")
        remove_entry "$domain"
        echo "Removed entry: $domain"
        ;;
    *)
        echo "Invalid action. Use 'add' or 'remove'"
        exit 1
        ;;
esac

