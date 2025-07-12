#!/bin/bash
set -e

# -------------------------------------
# Ensure whiptail is available
# -------------------------------------
if ! command -v whiptail &> /dev/null; then
  echo "Installing whiptail for interactive selection..."
  sudo apt update > /dev/null 2>&1 && sudo apt install -y whiptail > /dev/null 2>&1
fi

# -------------------------------------
# Show checklist
# -------------------------------------
CHOICES=$(whiptail --title "Dev Setup Selector" --checklist \
"Choose the packages to install using SPACE to select and ENTER to confirm:" 20 78 10 \
"git"            "Git"                                ON \
"docker"         "Docker Engine"                      ON \
"vscode"         "Visual Studio Code"                 ON \
"chrome"         "Google Chrome"                      ON \
"toolbox"        "JetBrains Toolbox"                  ON \
"php"            "PHP & Composer"                     ON \
"nvm"            "NVM + Node.js LTS"                  ON \
"zsh"            "Zsh + Oh My Zsh"                    ON \
3>&1 1>&2 2>&3)

# Convert choices into flags
CHOICES=$(echo "$CHOICES" | tr -d '"')

for choice in $CHOICES; do
  case $choice in
    "git") INSTALL_GIT=true ;;
    "docker") INSTALL_DOCKER=true ;;
    "vscode") INSTALL_VSCODE=true ;;
    "chrome") INSTALL_CHROME=true ;;
    "toolbox") INSTALL_TOOLBOX=true ;;
    "php") INSTALL_PHP_COMPOSER=true ;;
    "nvm") INSTALL_NVM=true ;;
    "zsh") INSTALL_ZSH=true ;;
  esac
done

# -------------------------------------
# System Update + Git First
# -------------------------------------
echo "📦 Updating system..."
sudo apt update > /dev/null 2>&1 && sudo apt upgrade -y > /dev/null 2>&1

# -------------------------------------
# Configure Git
# -------------------------------------
if [ "$CONFIGURE_GIT" = true ]; then 
  echo "Installing and configuring git..."
  sudo apt install -y git > /dev/null 2>&1
  echo "🛠 Let's configure Git!"
  read -p "Enter your Git username: " git_username
  read -p "Enter your Git email: " git_email
  read -p "Do you want to set a default Git editor? (leave blank to skip): " git_editor
  
  echo ""
  echo "Git will be configured as:"
  echo "  Name : $git_username"
  echo "  Email: $git_email"
  [ -n "$git_editor" ] && echo "  Editor: $git_editor"
  read -p "Proceed with these settings? (y/n): " confirm_git
  
  if [[ "$confirm_git" =~ ^[Yy]$ ]]; then
    git config --global user.name "$git_username" > /dev/null 2>&1
    git config --global user.email "$git_email" > /dev/null 2>&1
    [ -n "$git_editor" ] && git config --global core.editor "$git_editor" > /dev/null 2>&1
    echo "✅ Git configured successfully!"
  else
    echo "❌ Git configuration skipped."
  fi
fi

# -------------------------------------
# Install Docker
# -------------------------------------
if [ "$INSTALL_DOCKER" = true ]; then
  echo "🐳 Installing Docker..."
  sudo apt install -y ca-certificates curl gnupg lsb-release > /dev/null 2>&1
  sudo install -m 0755 -d /etc/apt/keyrings > /dev/null 2>&1
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
      sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg > /dev/null 2>&1
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update > /dev/null 2>&1
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1
  sudo usermod -aG docker $USER > /dev/null 2>&1
fi

# -------------------------------------
# Install VS Code
# -------------------------------------
if [ "$INSTALL_VSCODE" = true ]; then
  echo "📝 Installing Visual Studio Code..."
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
  sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ > /dev/null 2>&1
  rm microsoft.gpg
  sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
  sudo apt update > /dev/null 2>&1
  sudo apt install -y code > /dev/null 2>&1
fi

# -------------------------------------
# Install Google Chrome
# -------------------------------------
if [ "$INSTALL_CHROME" = true ]; then
  echo "🌐 Installing Google Chrome..."
  wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt install -y ./google-chrome-stable_current_amd64.deb > /dev/null 2>&1
  rm google-chrome-stable_current_amd64.deb
fi

# -------------------------------------
# Install JetBrains Toolbox
# -------------------------------------
if [ "$INSTALL_TOOLBOX" = true ]; then
  echo "🧰 Installing Jetbrains Toolbox..."

  # Get the latest toolbox URL by scraping the JetBrains Toolbox download page
  DOWNLOAD_URL=$(curl -s https://www.jetbrains.com/toolbox-app/ | grep -oP 'https://download\.jetbrains\.com/toolbox/jetbrains-toolbox-[^"]+\.tar\.gz' | head -n 1)
  DOWNLOAD_PATH=~/Downloads/$(basename "$DOWNLOAD_URL")

  if [ -z "$DOWNLOAD_URL" ]; then
    echo "❌ Failed to fetch the latest JetBrains Toolbox URL."
    exit 1
  fi
  
  wget "$DOWNLOAD_URL" -O "$DOWNLOAD_PATH" > /dev/null 2>&1fi
fi

# -------------------------------------
# Install PHP & Composer
# -------------------------------------
if [ "$INSTALL_PHP_COMPOSER" = true ]; then
  echo "🐘 Installing PHP and Composer..."
  sudo apt install -y php-cli php-mbstring unzip curl > /dev/null 2>&1
  EXPECTED_SIGNATURE=$(curl -s https://composer.github.io/installer.sig)
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  ACTUAL_SIGNATURE=$(php -r "echo hash_file('sha384', 'composer-setup.php');")
  if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
    echo "ERROR: Invalid Composer installer signature"
    rm composer-setup.php
    exit 1
  fi
  php composer-setup.php --install-dir=/usr/local/bin --filename=composer > /dev/null 2>&1
  rm composer-setup.php
fi

# -------------------------------------
# Install NVM & Node.js LTS
# -------------------------------------
if [ "$INSTALL_NVM" = true ]; then
  echo "🟢 Installing NVM and Node.js LTS..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash > /dev/null 2>&1
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install --lts > /dev/null 2>&1
  nvm use --lts > /dev/null 2>&1
  nvm alias default 'lts/*' > /dev/null 2>&1
fi

# -------------------------------------
# Install Zsh & Oh My Zsh
# -------------------------------------
if [ "$INSTALL_ZSH" = true ]; then
  echo "🐚 Installing Zsh and Oh My Zsh..."
  sudo apt install -y zsh curl git > /dev/null 2>&1
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh > /dev/null 2>&1)" || true
  fi
  echo "Setting Zsh as your default shell (will apply next login)..."
  chsh -s $(which zsh) > /dev/null 2>&1
fi

echo "🎉 All selected installations are complete!"
