#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

VERSION=${VERSION:-"latest"}
BINARY="linux-amd64"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

if which vault > /dev/null 2>&1; then
    echo "vault is already available with version $(vault --version)"
    exit 1
fi


wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vault

echo "Done!"