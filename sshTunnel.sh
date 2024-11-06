#!/bin/bash

# Display help menu
function show_help() {
    echo "A simple script to simplify SSH port forwarding, making it easier to manage connections and add custom SSH options if needed."
    echo "Usage: ./sshTunnel.sh -H [RHOST] -L [local port] -R [remote port] [-p SSH port] -u [username] [-i identity_file] [--ssh-arg \"custom SSH args\"] [--list]"
    echo
    echo "Options:"
    echo "  -H             Remote host IP address"
    echo "  -L             Local port to forward to"
    echo "  -R             Remote port on the RHOST to forward"
    echo "  -p             SSH port (optional, default is 22)"
    echo "  -u             SSH username"
    echo "  -i             SSH private key file (optional, for key-based authentication)"
    echo "  --ssh-arg      Additional custom SSH arguments (e.g., \"-o StrictHostKeyChecking=no\")"
    echo "  --list         List all active SSH port forwardings and allow to close one"
    echo
    echo "Example:"
    echo "  ./sshTunnel.sh -H 10.10.10.184 -L 8080 -R 80 -p 2222 -u user -i /path/to/keyfile --ssh-arg \"-o StrictHostKeyChecking=no\""
    echo "  ./sshTunnel.sh --list"
    echo
}

# Default SSH port
ssh_port=22
identity_file=""
ssh_custom_args=""

# Function to list all active SSH tunnels with detailed forwarding information
function list_tunnels() {
    # Using regex to grep and identify SSH tunnel forwarding details
    connections=()
    while IFS= read -r line; do
        connections+=("$line")
    done < <(ps aux | grep "[s]sh -fN" | grep -Eo '\b([1-9][0-9]{0,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5]):([0-9]{1,3}\.){3}[0-9]{1,3}:[1-9][0-9]{0,4}\b' | while read -r forwarding; do
        pid=$(ps aux | grep "[s]sh -fN" | grep "$forwarding" | awk '{print $2}')
        user=$(ps aux | grep "[s]sh -fN" | grep "$forwarding" | awk '{print $1}')
        local_port=$(echo "$forwarding" | cut -d':' -f1)
        remote_ip=$(echo "$forwarding" | cut -d':' -f2)
        remote_port=$(echo "$forwarding" | cut -d':' -f3)
        printf "%s | %s | %s | %s -> %s:%s\n" "$pid" "$user" "$local_port" "$remote_ip" "$remote_port"
    done)

    # Check if there are no active connections
    if [[ ${#connections[@]} -eq 0 ]]; then
        echo "No active connections found."
        exit 0
    fi

    # Print headers only if there are active connections
    echo "Active SSH Port Forwarding Connections:"
    echo "--------------------------------------"
    echo "No. | PID     | User       | Forwarding (Local -> Remote)"
    echo "--------------------------------------"

    # Display the connections with numbering
    for i in "${!connections[@]}"; do
        echo "$((i + 1)). ${connections[i]}"
    done

    # Loop for user selection
    while true; do
        echo
        read -p "Enter the connection number to terminate (or press Enter to cancel): " choice
        
        # Exit if no selection is made
        if [[ -z "$choice" ]]; then
            echo "No connection terminated."
            break
        fi

        # Validate the choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#connections[@]} )); then
            selected_pid=$(echo "${connections[choice-1]}" | awk '{print $1}')
            kill -9 "$selected_pid"
            echo "Connection with PID $selected_pid terminated."
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -H)
            rhost="$2"
            shift 2
            ;;
        -L)
            local_port="$2"
            shift 2
            ;;
        -R)
            remote_port="$2"
            shift 2
            ;;
        -p)
            ssh_port="$2"
            shift 2
            ;;
        -u)
            user="$2"
            shift 2
            ;;
        -i)
            identity_file="$2"
            shift 2
            ;;
        --ssh-arg)
            ssh_custom_args="$2"
            shift 2
            ;;
        --list)
            list_tunnels
            exit 0
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Invalid option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check for required arguments
if [[ -z "$rhost" || -z "$local_port" || -z "$remote_port" || -z "$user" ]]; then
    echo "Error: Missing required arguments."
    show_help
    exit 1
fi

# Construct SSH command with or without identity file
ssh_command="ssh -fN -L ${local_port}:127.0.0.1:${remote_port} -p ${ssh_port} ${user}@${rhost}"

# Add identity file if specified
if [[ -n "$identity_file" ]]; then
    ssh_command+=" -i \"$identity_file\""
fi

# Add custom SSH arguments if specified
if [[ -n "$ssh_custom_args" ]]; then
    ssh_command+=" $ssh_custom_args"
fi

# Execute SSH command safely with eval
eval "$ssh_command"

# Confirm the port forwarding is active
echo "Port forwarding is active: 127.0.0.1:${local_port} -> ${rhost}:${remote_port} via SSH port ${ssh_port}."
