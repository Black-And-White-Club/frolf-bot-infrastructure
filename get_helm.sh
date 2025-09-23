#!/bin/bash
# Script to install Helm
set -e

if command -v helm &> /dev/null; then
    echo "Helm is already installed"
    helm version
    exit 0
fi

echo "Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "Helm installation complete"
helm version
