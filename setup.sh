#!/usr/bin/env bash
set -e

echo "🚀 Iniciando preparación del entorno de desarrollo..."

### ===============================
### 1️⃣ Actualizar sistema base
### ===============================
sudo dnf update -y
sudo dnf install -y curl wget git unzip tar gcc gcc-c++ make zsh

### ===============================
### 2️⃣ Instalar PHP 8.3
### ===============================
echo "🔹 Instalando PHP 8.3 y extensiones comunes..."
sudo dnf install -y dnf-plugins-core
sudo dnf module reset php -y
sudo dnf module enable php:8.3 -y
sudo dnf install -y php php-cli php-mbstring php-xml php-curl php-intl php-pdo php-mysqlnd php-bcmath php-json php-zip

# Verificar versión
php -v

### ===============================
### 3️⃣ Instalar Composer
### ===============================
echo "🔹 Instalando Composer..."
EXPECTED_SIGNATURE=$(curl -s https://composer.github.io/installer.sig)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE=$(php -r "echo hash_file('sha384', 'composer-setup.php');")

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
    echo '❌ Composer installer corrupto'
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php

composer --version

### ===============================
### 4️⃣ Instalar Docker y Docker Compose
### ===============================
echo "🔹 Instalando Docker y Docker Compose..."
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Habilitar y arrancar Docker
sudo systemctl enable docker
sudo systemctl start docker

# Añadir usuario actual a grupo docker
sudo usermod -aG docker $USER

docker --version
docker compose version

### ===============================
### 5️⃣ Instalar NVM + Node.js LTS
### ===============================
echo "🔹 Instalando NVM y Node.js LTS..."
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

# Cargar NVM en este shell
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Instalar Node.js LTS
nvm install --lts
nvm use --lts
node -v
npm -v

### ===============================
### 6️⃣ Instalar Zsh + Oh My Zsh
### ===============================
echo "🔹 Instalando Zsh y Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Cambiar shell por defecto a zsh
chsh -s $(which zsh)

echo "✅ Entorno de desarrollo listo. Reinicia tu terminal para que Zsh y NVM funcionen correctamente."
