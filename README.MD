# SSH Tunneling Helper Script

A simple Bash script to facilitate SSH port forwarding. This script simplifies the setup and management of SSH port forwarding connections by allowing easy configuration and optional custom SSH arguments.

## Requirements

- **Bash**: This script is designed to run in a Bash environment.
- **OpenSSH**: The script requires `ssh` to perform port forwarding. Make sure `OpenSSH` is installed on your system.
- **Permissions**: Ensure that you have the necessary permissions to access the target SSH server and that any custom SSH arguments used are valid for your environment.

## Features

- Local and remote port forwarding with specified ports.
- Optional SSH key-based authentication.
- Custom SSH arguments support (`--ssh-arg`).
- Lists active SSH tunnels with the ability to terminate specific connections.

## Usage

```bash
./sshTunnel.sh -H [RHOST] -L [local port] -R [remote port] [-p SSH port] -u [username] [-i identity_file] [--ssh-arg "custom SSH args"] [--list]

