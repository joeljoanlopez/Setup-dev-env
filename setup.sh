#!/bin/bash

set -e

echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# -------------------------------
# Install Docker Engine
# -------------------------------
echo "Installing Docker..."
sudo apt install -y ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Post-install steps for Docker
sudo usermod -aG docker $USER
newgrp docker

# -------------------------------
# Install Visual Studio Code
# -------------------------------
echo "Installing VS Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
rm microsoft.gpg

sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install -y code

# -------------------------------
# Install Google Chrome
# -------------------------------
echo "Installing Google Chrome..."
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

# -------------------------------
# Install JetBrains Toolbox
# -------------------------------
echo "Installing JetBrains Toolbox..."
JETBRAINS_URL=$(curl -s https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release | \
    grep -oP 'https://download.jetbrains.com/toolbox/jetbrains-toolbox-\K[0-9.-]+(?=\.tar\.gz)' | \
    head -n 1)

JETBRAINS_VERSION="jetbrains-toolbox-${JETBRAINS_URL}"
wget "https://download.jetbrains.com/toolbox/${JETBRAINS_VERSION}.tar.gz"
tar -xzf "${JETBRAINS_VERSION}.tar.gz"
sudo mv jetbrains-toolbox-* /opt/jetbrains-toolbox
sudo chmod +x /opt/jetbrains-toolbox/jetbrains-toolbox
/opt/jetbrains-toolbox/jetbrains-toolbox &
rm "${JETBRAINS_VERSION}.tar.gz"

# -------------------------------
# Install PHP & Composer
# -------------------------------
echo "Installing PHP and Composer..."
sudo apt install -y php-cli php-mbstring unzip curl

EXPECTED_SIGNATURE=$(curl -s https://composer.github.io/installer.sig)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE=$(php -r "echo hash_file('sha384', 'composer-setup.php');")

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
    >&2 echo "ERROR: Invalid Composer installer signature"
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php

# -------------------------------
# Install NVM and Node.js (LTS)
# -------------------------------
echo "Installing NVM and Node.js LTS..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

nvm install --lts
nvm use --lts
nvm alias default 'lts/*'

echo "✅ All installations completed!"
