#!/bin/bash

# Variables
check_interval=300  # Check every 5 minutes (default)
hosts=("host1" "host2" "host3")  # Define your hosts here
domain_name=""  # Define your domain name here
ddns_password=""  # Define your dynamic DNS password here
previous_ip=""  # No previous IP at the start
ip_check_server=${1:-"https://api.ipify.org"}  # Server to check IP from, default is https://api.ipify.org

# Function to check if string is a valid IP address
is_valid_ip() {
    local ip=$1
    local valid_ip_regex="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    if [[ $ip =~ $valid_ip_regex ]]; then
        return 0
    else
        return 1
    fi
}

# Function to get current IP
get_current_ip() {
    curl -s $ip_check_server
}

# Function to update IP
update_ip() {
    local new_ip=$1
    local host=$2
    local url="https://dynamicdns.park-your-domain.com/update?host=$host&domain=$domain_name&password=$ddns_password&ip=$new_ip"
    local status_code=$(curl -o /dev/null -s -w "%{http_code}\n" "$url")
    echo $status_code
}

# Main script
while true; do
    current_ip=$(get_current_ip)
    if is_valid_ip "$current_ip"; then
        if [ "$current_ip" != "$previous_ip" ]; then
            for host in "${hosts[@]}"; do
                update_status=$(update_ip "$current_ip" "$host")
                if [ "$update_status" -eq 200 ]; then
                    echo "IP successfully updated for $host to $current_ip"
                else
                    echo "Failed to update IP for $host. HTTP status code: $update_status"
                fi
            done
            previous_ip=$current_ip
        fi
    else
        echo "Error: Invalid IP address received from $ip_check_server"
    fi
    sleep $check_interval
done

