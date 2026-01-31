#!/bin/bash

# Comprobación de whiptail
if ! command -v whiptail &> /dev/null; then
    sudo apt update && sudo apt install -y whiptail
fi

# MENU DE SELECCIÓN ACTUALIZADO
CHOICES=$(whiptail --title "Instalador Ubuntu Dev" --checklist \
"Marca con ESPACIO qué quieres instalar:" 22 78 14 \
"GIT" "Git" ON \
"DOCKER" "Docker + Compose" ON \
"PHP" "PHP 8.3 + Composer + Exts" ON \
"NODE" "NVM + Node.js LTS" ON \
"ZSH" "Oh My Zsh" ON \
"BRAVE" "Brave Browser" ON \
"VSCODE" "VS Code" ON \
"WARP" "Warp Terminal" ON \
"JB_TOOLBOX" "JetBrains Toolbox" ON \
"UNITY" "Unity Hub" ON \
"STEAM" "Steam" ON \
"DISCORD" "Discord" ON \
"TELEGRAM" "Telegram" ON \
"SPOTIFY" "Spotify" ON \
"TAILSCALE" "Tailscale" ON \
"SYNCTHING" "Syncthing" ON \
"BTOP" "Btop" ON \
3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then echo "Cancelado."; exit 0; fi

echo "--- Iniciando instalación... ---"

# Actualizar sistema y dependencias básicas
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget gpg software-properties-common apt-transport-https build-essential unzip
sudo mkdir -p /etc/apt/keyrings

# --- INSTALACIONES ---

# 1. GIT
if [[ $CHOICES == *"GIT"* ]]; then sudo apt install -y git; fi

# 2. DOCKER
if [[ $CHOICES == *"DOCKER"* ]]; then
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker $USER
fi

# 3. PHP 8.3 + COMPOSER
if [[ $CHOICES == *"PHP"* ]]; then
    echo ">>> Instalando PHP 8.3 y extensiones..."
    # Repositorio oficial para versiones específicas de PHP
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt update
    # Instalar PHP 8.3 y las extensiones solicitadas + comunes (curl, mbstring, xml)
    sudo apt install -y php8.3 php8.3-cli php8.3-common php8.3-bcmath php8.3-zip php8.3-gd php8.3-curl php8.3-mbstring php8.3-xml
    
    echo ">>> Instalando Composer..."
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
fi

# 4. NODEJS (NVM + LTS)
if [[ $CHOICES == *"NODE"* ]]; then
    echo ">>> Instalando NVM y Node LTS..."
    # Instalar NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Cargar NVM temporalmente para instalar Node ahora mismo
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Instalar la versión LTS
    nvm install --lts
    nvm use --lts
fi

# 5. BRAVE
if [[ $CHOICES == *"BRAVE"* ]]; then
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    sudo apt update && sudo apt install -y brave-browser
fi

# 6. VS CODE
if [[ $CHOICES == *"VSCODE"* ]]; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    rm packages.microsoft.gpg
    sudo apt update && sudo apt install -y code
fi

# 7. WARP
if [[ $CHOICES == *"WARP"* ]]; then
    wget -qO- https://app.warp.dev/apt/gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/warpdotdev.gpg > /dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/warpdotdev.gpg] https://app.warp.dev/apt/ stable main" | sudo tee /etc/apt/sources.list.d/warpdotdev.list
    sudo apt update && sudo apt install -y warp-terminal
fi

# 8. UNITY
if [[ $CHOICES == *"UNITY"* ]]; then
    wget -qO - https://hub.unity3d.com/linux/keys/public | gpg --dearmor | sudo tee /usr/share/keyrings/Unity_Technologies_ApS.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/Unity_Technologies_ApS.gpg] https://hub.unity3d.com/linux/repos/deb stable main" | sudo tee /etc/apt/sources.list.d/unityhub.list
    sudo apt update && sudo apt install -y unityhub
fi

# 9. SYNCTHING
if [[ $CHOICES == *"SYNCTHING"* ]]; then
    sudo curl -fsSL https://syncthing.net/release-key.txt -o /etc/apt/keyrings/syncthing-archive-keyring.asc
    echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.asc] https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
    sudo apt update && sudo apt install -y syncthing
fi

# 10. TAILSCALE
if [[ $CHOICES == *"TAILSCALE"* ]]; then
    curl -fsSL https://tailscale.com/install.sh | sh
fi

# 11. OTROS (Snaps/Apt)
[[ $CHOICES == *"BTOP"* ]] && sudo apt install -y btop
[[ $CHOICES == *"STEAM"* ]] && sudo apt install -y steam-installer
[[ $CHOICES == *"DISCORD"* ]] && sudo snap install discord
[[ $CHOICES == *"TELEGRAM"* ]] && sudo snap install telegram-desktop
[[ $CHOICES == *"SPOTIFY"* ]] && sudo snap install spotify

# 12. JETBRAINS
if [[ $CHOICES == *"JB_TOOLBOX"* ]]; then
    echo ">>> Bajando JetBrains Toolbox..."
    JB_URL=$(curl -s 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' | grep -Po '"linux":.*?"link":"\K[^"]+')
    mkdir -p $HOME/Downloads/JetBrains
    wget -O $HOME/Downloads/JetBrains/toolbox.tar.gz "$JB_URL"
fi

# 13. ZSH (Final)
if [[ $CHOICES == *"ZSH"* ]]; then
    sudo apt install -y zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        sudo chsh -s $(which zsh) $USER
        
        # Asegurar que NVM carga en ZSH si se instaló
        if [[ $CHOICES == *"NODE"* ]]; then
             echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
             echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
        fi
    fi
fi

sudo apt autoremove -y
echo "¡Instalación completada! Reinicia el equipo."
