#!/bin/bash

# Asegurarse de que whiptail está instalado (suele venir por defecto en Ubuntu)
if ! command -v whiptail &> /dev/null; then
    sudo apt update && sudo apt install -y whiptail
fi

# Definir la lista de opciones para el menú
# Formato: TAG "Descripción" ESTADO
CHOICES=$(whiptail --title "Instalador Personalizado Ubuntu" --checklist \
"Usa ESPACIO para marcar/desmarcar y ENTER para confirmar." 20 78 12 \
"GIT" "Git - Control de versiones" ON \
"DOCKER" "Docker Engine & Compose" ON \
"ZSH" "Oh My Zsh + Zsh Shell" ON \
"BRAVE" "Brave Browser" ON \
"VSCODE" "Visual Studio Code" ON \
"WARP" "Warp Terminal" ON \
"JB_TOOLBOX" "JetBrains Toolbox" ON \
"UNITY" "Unity Hub" ON \
"STEAM" "Steam" ON \
"DISCORD" "Discord" ON \
"TELEGRAM" "Telegram Desktop" ON \
"SPOTIFY" "Spotify" ON \
"TAILSCALE" "Tailscale VPN" ON \
"SYNCTHING" "Syncthing" ON \
"BTOP" "Btop (Monitor de recursos)" ON \
3>&1 1>&2 2>&3)

# Si el usuario cancela, salir
if [ $? -ne 0 ]; then
    echo "Instalación cancelada por el usuario."
    exit 0
fi

# Actualizar sistema base antes de empezar
echo "--- Actualizando repositorios base... ---"
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget gpg software-properties-common apt-transport-https

# Crear directorio de llaveros si no existe
sudo mkdir -p /etc/apt/keyrings

# --- BLOQUE DE INSTALACIÓN ---

# 1. GIT
if [[ $CHOICES == *"GIT"* ]]; then
    echo ">>> Instalando Git..."
    sudo apt install -y git build-essential
fi

# 2. DOCKER
if [[ $CHOICES == *"DOCKER"* ]]; then
    echo ">>> Preparando Docker..."
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker $USER
fi

# 3. BRAVE BROWSER
if [[ $CHOICES == *"BRAVE"* ]]; then
    echo ">>> Preparando Brave..."
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    sudo apt update
    sudo apt install -y brave-browser
fi

# 4. VS CODE
if [[ $CHOICES == *"VSCODE"* ]]; then
    echo ">>> Preparando VS Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    rm packages.microsoft.gpg
    sudo apt update
    sudo apt install -y code
fi

# 5. WARP TERMINAL
if [[ $CHOICES == *"WARP"* ]]; then
    echo ">>> Preparando Warp..."
    wget -qO- https://app.warp.dev/apt/gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/warpdotdev.gpg > /dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/warpdotdev.gpg] https://app.warp.dev/apt/ stable main" | sudo tee /etc/apt/sources.list.d/warpdotdev.list
    sudo apt update
    sudo apt install -y warp-terminal
fi

# 6. UNITY HUB
if [[ $CHOICES == *"UNITY"* ]]; then
    echo ">>> Preparando Unity Hub..."
    wget -qO - https://hub.unity3d.com/linux/keys/public | gpg --dearmor | sudo tee /usr/share/keyrings/Unity_Technologies_ApS.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/Unity_Technologies_ApS.gpg] https://hub.unity3d.com/linux/repos/deb stable main" | sudo tee /etc/apt/sources.list.d/unityhub.list
    sudo apt update
    sudo apt install -y unityhub
fi

# 7. SYNCTHING
if [[ $CHOICES == *"SYNCTHING"* ]]; then
    echo ">>> Preparando Syncthing..."
    sudo curl -fsSL https://syncthing.net/release-key.txt -o /etc/apt/keyrings/syncthing-archive-keyring.asc
    echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.asc] https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
    sudo apt update
    sudo apt install -y syncthing
fi

# 8. TAILSCALE
if [[ $CHOICES == *"TAILSCALE"* ]]; then
    echo ">>> Instalando Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
fi

# 9. APPS SIMPLES (APT/SNAP)
if [[ $CHOICES == *"BTOP"* ]]; then
    sudo apt install -y btop
fi

if [[ $CHOICES == *"STEAM"* ]]; then
    sudo apt install -y steam-installer
fi

if [[ $CHOICES == *"DISCORD"* ]]; then
    sudo snap install discord
fi

if [[ $CHOICES == *"TELEGRAM"* ]]; then
    sudo snap install telegram-desktop
fi

if [[ $CHOICES == *"SPOTIFY"* ]]; then
    sudo snap install spotify
fi

# 10. JETBRAINS TOOLBOX (Manual)
if [[ $CHOICES == *"JB_TOOLBOX"* ]]; then
    echo ">>> Descargando JetBrains Toolbox..."
    JB_URL=$(curl -s 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' | grep -Po '"linux":.*?"link":"\K[^"]+')
    mkdir -p $HOME/Downloads/JetBrains
    wget -O $HOME/Downloads/JetBrains/toolbox.tar.gz "$JB_URL"
    echo "Toolbox descargado en ~/Downloads/JetBrains (requiere instalación manual final)."
fi

# 11. OH MY ZSH (Al final para que no interrumpa)
if [[ $CHOICES == *"ZSH"* ]]; then
    echo ">>> Instalando Zsh y Oh My Zsh..."
    sudo apt install -y zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        sudo chsh -s $(which zsh) $USER
    fi
fi

# LIMPIEZA
sudo apt autoremove -y

echo "-----------------------------------------------------"
echo "¡Proceso finalizado!"
echo "Reinicia el sistema para aplicar cambios (grupos de Docker, Shell Zsh, etc)."
echo "-----------------------------------------------------"
