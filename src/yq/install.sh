#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

VERSION=${VERSION:-"latest"}
BINARY="yq_linux_amd64"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

if which yq > /dev/null 2>&1; then
    echo "YQ is already available with version $(yq --version)"
    exit 1
fi

echo "apt update"
apt-get update -y

echo "Install dependencies"
apt-get install wget -y

wget https://github.com/mikefarah/yq/releases/${VERSION}/download/${BINARY} -O /usr/bin/yq && chmod +x /usr/bin/yq

echo "Done!"