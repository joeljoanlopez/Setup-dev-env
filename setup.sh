#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting Fedora Development Environment Setup..."
echo "=================================================="

### ===============================
### 1️⃣ Update System & Install Base Tools
### ===============================
echo ""
echo "📦 Step 1/6: Updating system and installing base packages..."
sudo dnf update -y
sudo dnf install -y curl wget git unzip tar gcc gcc-c++ make vim nano

### ===============================
### 2️⃣ Install PHP 8.3 & Composer
### ===============================
echo ""
echo "🐘 Step 2/6: Installing PHP 8.3 and Composer..."

# Install EPEL and Remi repository
sudo dnf install -y https://rpms.remirepo.net/fedora/remi-release-$(rpm -E %fedora).rpm 2>/dev/null || echo "Remi repo already installed"

# Enable PHP 8.3 from Remi
sudo dnf module reset php -y
sudo dnf module enable php:remi-8.3 -y

# Install PHP and common extensions
sudo dnf install -y \
  php \
  php-cli \
  php-common \
  php-fpm \
  php-mysqlnd \
  php-pdo \
  php-mbstring \
  php-xml \
  php-curl \
  php-intl \
  php-bcmath \
  php-gd \
  php-zip \
  php-opcache \
  php-json

echo "✓ PHP version installed:"
php -v

# Install Composer
echo "Installing Composer..."
EXPECTED_CHECKSUM="$(curl -sS https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    echo "❌ ERROR: Invalid Composer installer checksum"
    rm composer-setup.php
    exit 1
fi

sudo php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php
echo "✓ Composer version installed:"
composer --version

### ===============================
### 3️⃣ Install Docker & Docker Compose
### ===============================
echo ""
echo "🐳 Step 3/6: Installing Docker and Docker Compose..."

# Add Docker repository
sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo 2>/dev/null || echo "Docker repo already added"

# Install Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add current user to docker group
sudo usermod -aG docker $USER
echo "✓ Docker version installed:"
docker --version
docker compose version

echo "⚠️  Note: You need to log out and back in for docker group membership to take effect"

### ===============================
### 4️⃣ Install NVM and Node.js LTS
### ===============================
echo ""
echo "📗 Step 4/6: Installing NVM and Node.js LTS..."

# Install NVM
export NVM_DIR="$HOME/.nvm"
if [ -d "$NVM_DIR" ]; then
    echo "NVM already installed, updating..."
fi

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Load NVM into current shell
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install Node.js LTS
nvm install --lts
nvm use --lts
nvm alias default lts/*
echo "✓ Node.js version installed:"
node -v
echo "✓ npm version installed:"
npm -v

### ===============================
### 5️⃣ Configure Git
### ===============================
echo ""
echo "🔧 Step 5/6: Configuring Git..."

git --version
echo ""
read -p "Would you like to configure Git user info now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter your Git username: " git_username
    read -p "Enter your Git email: " git_email
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
    echo "✓ Git configured successfully"
else
    echo "⚠️  Skipping Git configuration. You can configure it later with:"
    echo "   git config --global user.name 'Your Name'"
    echo "   git config --global user.email 'your@email.com'"
fi

### ===============================
### 6️⃣ Install Zsh & Oh My Zsh
### ===============================
echo ""
echo "🎨 Step 6/6: Installing Zsh and Oh My Zsh..."

# Install Zsh
sudo dnf install -y zsh

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "");
fi
    echo "✓ Oh My Zsh installed"
else
    echo "✓ Oh My Zsh already installed"
fi

# Ensure NVM is loaded in .zshrc
if ! grep -q 'NVM_DIR' "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" << 'EOF'

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
    echo "✓ NVM configuration added to .zshrc"
fi

# Change default shell to Zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    echo ""
    echo "Changing default shell to Zsh..."
    chsh -s $(which zsh)
    echo "✓ Default shell changed to Zsh"
else
    echo "✓ Zsh is already the default shell"
fi

### ===============================
### 🎉 Installation Complete
### ===============================
echo ""
echo "=================================================="
echo "✅ Development environment setup complete!"
echo "=================================================="
echo ""
echo "📋 Installed software:"
echo "  • PHP 8.3 with Composer"
echo "  • Docker & Docker Compose"
echo "  • Node.js LTS (via NVM)"
echo "  • Git"
echo "  • Zsh with Oh My Zsh"
echo ""
echo "⚠️  IMPORTANT: Please do the following:"
echo "  1. Log out and log back in (or reboot) for Docker group to take effect"
echo "  2. Open a new terminal or run: exec zsh"
echo ""
echo "🚀 Happy coding!"