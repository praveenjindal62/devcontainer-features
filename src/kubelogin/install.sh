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

if which kubelogin > /dev/null 2>&1; then
    echo "kubelogin is already available with version $(yq --version)"
    exit 1
fi

echo "apt update"
apt-get update -y

echo "Install dependencies"
apt-get install wget unzip -y

wget https://github.com/Azure/kubelogin/releases/download/${VERSION}/kubelogin-${BINARY}.zip -O /tmp/kubelogin-${BINARY}.zip && \
unzip /tmp/kubelogin-${BINARY}.zip -d /tmp/kubelogin && \
mv /tmp/kubelogin/bin/$(echo $BINARY | sed 's/-/_/g')/kubelogin /usr/local/bin/kubelogin && \
chmod +x /usr/local/bin/kubelogin

echo "Done!"