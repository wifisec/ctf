#!/bin/bash

# --------------------------------------------------------------------
# SYNOPSIS
#     Optimized port scanner with banner grabbing using TCP and UDP sockets.
#
# DESCRIPTION
#     This script scans specified ports on a given target IP address,
#     grabs banners for open ports using TCP and UDP sockets, and logs the results with error checking.
#     Allows specifying single ports and port ranges, and enables TCP or UDP scanning using flags.
#     Optimized for speed with timeouts and parallel scanning. Does not require netcat.
#     Only open ports are included in the summary table.
#
# USAGE
#     ./bscan.sh <target_ip> <ports> [<timeout>] [-tcp | -udp]
#
# ARGUMENTS
#     <target_ip>  - The target IP address to scan (e.g., 192.168.1.1).
#     <ports>      - The ports to scan (e.g., "22,80,1000-1010").
#     <timeout>    - Connection timeout in seconds (default: 1).
#     -tcp         - Enable TCP scanning.
#     -udp         - Enable UDP scanning.
#
# AUTHOR
#     Adair John Collins
#
# VERSION
#     1.5
# --------------------------------------------------------------------

# Check if correct number of arguments are provided
if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 <target_ip> <ports> [<timeout>] [-tcp | -udp]"
    exit 1
fi

# Variables
TARGET_IP="$1"
PORTS="$2"
TIMEOUT="${3:-1}" # Default timeout to 1 second if not provided
SCAN_TYPE="${4:--tcp}" # Default to TCP if not specified
LOG_FILE="port_scan_$(date +%Y%m%d_%H%M%S).log"
SUMMARY_FILE=$(mktemp) # Temporary file for thread-safe summary
MAX_PARALLEL=10 # Limit concurrent scans

# Validate IP address format
if ! [[ "$TARGET_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "Error: Invalid IP address format."
    exit 1
fi

# Validate timeout (must be a positive integer)
if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]] || [ "$TIMEOUT" -le 0 ]; then
    echo "Warning: Invalid or zero timeout, using default of 1 second."
    TIMEOUT=1
fi

# Validate scan type
if [ "$SCAN_TYPE" != "-tcp" ] && [ "$SCAN_TYPE" != "-udp" ]; then
    echo "Error: Scan type must be -tcp or -udp."
    exit 1
fi

# Check for timeout command
if ! command -v timeout >/dev/null 2>&1; then
    echo "Error: 'timeout' command not found. Please install coreutils."
    exit 1
fi

# Initialize log file
: > "$LOG_FILE"

# Log message function with timestamp
log_message() {
    local message="$1"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') $message" | tee -a "$LOG_FILE"
}

# Function to validate port number
validate_port() {
    local port="$1"
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        log_message "Error: Invalid port $port. Skipping."
        return 1
    fi
    return 0
}

# Function to scan a single TCP port and grab banner
scan_tcp_port() {
    local port="$1"
    validate_port "$port" || return

    log_message "Scanning TCP port $port..."

    # Combine connection test and banner grabbing in a single timeout block
    banner=$(timeout "$TIMEOUT" bash -c "
        exec 3<>/dev/tcp/$TARGET_IP/$port 2>/dev/null || exit 1
        echo -e '\n' >&3 2>/dev/null
        cat <&3 2>/dev/null | tr -d '\0' | head -c 1000
        exec 3<&-
        exec 3>&-
    ")
    if [ $? -eq 0 ]; then
        log_message "TCP port $port is open."
        if [ -n "$banner" ]; then
            log_message "Banner for TCP port $port:\n$banner"
            echo "$TARGET_IP|TCP|$port|$banner" >> "$SUMMARY_FILE"
        else
            log_message "No banner received for TCP port $port."
            echo "$TARGET_IP|TCP|$port|No banner" >> "$SUMMARY_FILE"
        fi
    else
        log_message "TCP port $port is closed or filtered."
    fi
}

# Function to scan a single UDP port and grab banner
scan_udp_port() {
    local port="$1"
    validate_port "$port" || return

    log_message "Scanning UDP port $port..."

    # Combine connection test and banner grabbing in a single timeout block
    banner=$(timeout "$TIMEOUT" bash -c "
        exec 3<>/dev/udp/$TARGET_IP/$port 2>/dev/null || exit 1
        echo -e '\n' >&3 2>/dev/null
        cat <&3 2>/dev/null | tr -d '\0' | head -c 1000
        exec 3<&-
        exec 3>&-
    ")
    if [ $? -eq 0 ]; then
        log_message "UDP port $port is open."
        if [ -n "$banner" ]; then
            log_message "Banner for UDP port $port:\n$banner"
            echo "$TARGET_IP|UDP|$port|$banner" >> "$SUMMARY_FILE"
        else
            log_message "No banner received for UDP port $port."
            echo "$TARGET_IP|UDP|$port|No banner" >> "$SUMMARY_FILE"
        fi
    else
        log_message "UDP port $port is closed or filtered."
    fi
}

# Function to process the ports argument and scan ports in parallel
process_ports() {
    local ports_arg="$1"
    IFS=',' read -ra PORTS_ARRAY <<< "$ports_arg"

    # Use a counter to limit parallel jobs
    local job_count=0
    for port_spec in "${PORTS_ARRAY[@]}"; do
        if [[ "$port_spec" == *-* ]]; then
            IFS='-' read -ra RANGE <<< "$port_spec"
            if ! validate_port "${RANGE[0]}" || ! validate_port "${RANGE[1]}" || [ "${RANGE[0]}" -gt "${RANGE[1]}" ]; then
                log_message "Error: Invalid port range $port_spec. Skipping."
                continue
            fi
            for (( port=${RANGE[0]}; port<=${RANGE[1]}; port++ )); do
                if [ "$SCAN_TYPE" == "-tcp" ]; then
                    scan_tcp_port "$port" &
                elif [ "$SCAN_TYPE" == "-udp" ]; then
                    scan_udp_port "$port" &
                fi
                ((job_count++))
                # Limit concurrent jobs
                if [ "$job_count" -ge "$MAX_PARALLEL" ]; then
                    wait -n
                    ((job_count--))
                fi
            done
        else
            if validate_port "$port_spec"; then
                if [ "$SCAN_TYPE" == "-tcp" ]; then
                    scan_tcp_port "$port_spec" &
                elif [ "$SCAN_TYPE" == "-udp" ]; then
                    scan_udp_port "$port_spec" &
                fi
                ((job_count++))
                if [ "$job_count" -ge "$MAX_PARALLEL" ]; then
                    wait -n
                    ((job_count--))
                fi
            fi
        fi
    done
    wait # Wait for all remaining background jobs
}

# Function to display and log summary table
display_summary_table() {
    log_message "\nSummary Table:"
    log_message "IP Address | Protocol | Port | Banner"
    if [ -s "$SUMMARY_FILE" ]; then
        sort -n -t '|' -k 3 "$SUMMARY_FILE" | while IFS='|' read -r ip proto port banner; do
            log_message "$ip | $proto | $port | $banner"
        done
    else
        log_message "No open ports found."
    fi
    rm -f "$SUMMARY_FILE" # Clean up temporary file
}

# Main function to start the port scanning
main() {
    log_message "Checking if $TARGET_IP is reachable..."
    ping -c 1 -W 1 "$TARGET_IP" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        log_message "Error: $TARGET_IP is unreachable."
        rm -f "$SUMMARY_FILE"
        exit 1
    fi
    log_message "Starting port scanning on $TARGET_IP for ports: $PORTS with timeout $TIMEOUT seconds"
    process_ports "$PORTS"
    display_summary_table
    log_message "Port scanning completed. Results saved in $LOG_FILE."
}

# Run the main function
main
