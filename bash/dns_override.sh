#!/bin/bash

hosts_file="/etc/hosts"  # Modify this path according to your operating system

add_entry() {
    domain=$1
    ip=$2
    echo "$ip $domain" >> "$hosts_file"  # Append the entry to the host file
    echo "Added entry: $ip $domain"
}

remove_entry() {
    domain=$1
    sed -i "/$domain/d" "$hosts_file"  # Remove the line containing the specified domain from the host file
    echo "Removed entry: $domain"
}

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# Check the number of command-line arguments
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <domain> <ip>"
    exit 1
fi

domain=$1
ip=$2

# Check if domain is already in the hosts file
if grep -q -E "(^|\s)${domain}($|\s)" "$hosts_file"; then
    remove_entry "$domain"
else
    add_entry "$domain" "$ip"
fi
