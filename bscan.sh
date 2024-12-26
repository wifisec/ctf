#!/bin/bash

# --------------------------------------------------------------------
# SYNOPSIS
#     Simple port scanner with banner grabbing using TCP and UDP sockets.
#
# DESCRIPTION
#     This script scans specified ports on a given target IP address,
#     grabs banners using TCP and UDP sockets, and logs the results with error checking.
#     Allows specifying single ports and port ranges, and enables TCP or UDP scanning using flags.
#
# USAGE
#     ./bscan.sh <target_ip> <ports> <timeout> [-tcp | -udp]
#
# ARGUMENTS
#     <target_ip>  - The target IP address to scan.
#     <ports>      - The ports to scan (e.g., "22,80,1000-1010").
#     <timeout>    - Connection timeout in seconds.
#     -tcp         - Enable TCP scanning.
#     -udp         - Enable UDP scanning.
#
# AUTHOR
#     Adair John Collins
#
# VERSION
#     1.0
# --------------------------------------------------------------------

# Check if correct number of arguments are provided
if [ "$#" -lt 4 ]; then
    echo "Usage: $0 <target_ip> <ports> <timeout> [-tcp | -udp]"
    exit 1
fi

# Variables
TARGET_IP="$1"
PORTS="$2"
TIMEOUT="$3"
SCAN_TYPE="$4"
LOG_FILE="port_scan_$(date +%Y%m%d_%H%M%S).log"

# Initialize log file
: > "$LOG_FILE"

# Log message function
log_message() {
    local message="$1"
    echo -e "$message" | tee -a "$LOG_FILE"
}

# Function to scan a single TCP port and grab banner
scan_tcp_port() {
    local port="$1"
    log_message "\nScanning TCP port $port..."

    # Attempt to connect and grab banner using TCP socket
    exec 3<>/dev/tcp/"$TARGET_IP"/"$port"
    if [ $? -eq 0 ]; then
        log_message "TCP port $port is open."

        # Send empty data to initiate banner retrieval
        echo -e "\n" >&3
        sleep "$TIMEOUT"
        banner=$(cat <&3)
        if [ -n "$banner" ]; then
            log_message "Banner for TCP port $port:\n$banner"
        else
            log_message "No banner received for TCP port $port."
        fi
    else
        log_message "TCP port $port is closed or filtered."
    fi
    exec 3<&-
    exec 3>&-
}

# Function to scan a single UDP port and grab banner
scan_udp_port() {
    local port="$1"
    log_message "\nScanning UDP port $port..."

    # Attempt to send data and receive banner using UDP socket
    exec 3<>/dev/udp/"$TARGET_IP"/"$port"
    if [ $? -eq 0 ]; then
        log_message "UDP port $port is open."

        # Send empty data to initiate banner retrieval
        echo -e "\n" >&3
        sleep "$TIMEOUT"
        banner=$(cat <&3)
        if [ -n "$banner" ]; then
            log_message "Banner for UDP port $port:\n$banner"
        else
            log_message "No banner received for UDP port $port."
        fi
    else
        log_message "UDP port $port is closed or filtered."
    fi
    exec 3<&-
    exec 3>&-
}

# Function to process the ports argument and scan ports
process_ports() {
    local ports_arg="$1"
    IFS=',' read -ra PORTS_ARRAY <<< "$ports_arg"

    for port_spec in "${PORTS_ARRAY[@]}"; do
        if [[ "$port_spec" == *-* ]]; then
            IFS='-' read -ra RANGE <<< "$port_spec"
            for (( port=${RANGE[0]}; port<=${RANGE[1]}; port++ )); do
                if [ "$SCAN_TYPE" == "-tcp" ]; then
                    scan_tcp_port "$port"
                elif [ "$SCAN_TYPE" == "-udp" ]; then
                    scan_udp_port "$port"
                fi
            done
        else
            if [ "$SCAN_TYPE" == "-tcp" ]; then
                scan_tcp_port "$port_spec"
            elif [ "$SCAN_TYPE" == "-udp" ]; then
                scan_udp_port "$port_spec"
            fi
        fi
    done
}

# Main function to start the port scanning
main() {
    log_message "Starting port scanning on $TARGET_IP for ports: $PORTS"
    process_ports "$PORTS"
    log_message "\nPort scanning completed. Results saved in $LOG_FILE."
}

# Run the main function
main
