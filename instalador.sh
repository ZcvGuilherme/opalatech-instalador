#!/bin/bash

set -e

# ==============================
# CONFIGURAÇÕES
# ==============================

USUARIO_PADRAO="opalatech"

WALLPAPER_URL="./wallpaper.png"
WALLPAPER_NAME="evento-wallpaper.png"

# ==============================
# VERIFICA ROOT
# ==============================

if [ "$EUID" -ne 0 ]; then
    echo "Execute usando:"
    echo "curl -fsSL URL | sudo bash"
    exit 1
fi

echo ""
echo "=============================="
echo "ATUALIZANDO PACOTES"
echo "=============================="

apt update
apt upgrade -y

echo ""
echo "=============================="
echo "REMOVENDO NODE ANTIGO"
echo "=============================="

apt remove --purge -y \
nodejs npm libnode-dev libnode72

sudo apt autoremove -y
sudo apt clean

apt --fix-broken install -y

echo ""
echo "=============================="
echo "INSTALANDO DEPENDÊNCIAS"
echo "=============================="

apt install -y \
curl \
wget \
ca-certificates \
gnupg \
lsb-release \
apt-transport-https \
software-properties-common

echo ""
echo "=============================="
echo "INSTALANDO NODE 24"
echo "=============================="

curl -fsSL https://deb.nodesource.com/setup_24.x | bash -

apt install -y nodejs

echo ""
echo "=============================="
echo "REMOVENDO TYPESCRIPT ANTIGO"
echo "=============================="

npm uninstall -g typescript || true
npm cache clean --force || true

sudo apt autoremove -y
sudo apt clean

apt --fix-broken install -y

echo ""
echo "=============================="
echo "INSTALANDO TYPESCRIPT"
echo "=============================="

npm install -g typescript

echo ""
echo "=============================="
echo "INSTALANDO DOCKER"
echo "=============================="

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo ${UBUNTU_CODENAME}) stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update

apt install -y \
docker-ce \
docker-ce-cli \
containerd.io \
docker-buildx-plugin \
docker-compose-plugin

groupadd docker 2>/dev/null || true

usermod -aG docker "$USUARIO_PADRAO"

echo ""
echo "=============================="
echo "INSTALANDO DOCKER DESKTOP"
echo "=============================="

cd /tmp

wget -O docker-desktop-amd64.deb \
https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb

apt install -y ./docker-desktop-amd64.deb

echo ""
echo "=============================="
echo "REMOVENDO VS CODE ANTIGO"
echo "=============================="

apt remove --purge -y \
code code-insiders

flatpak uninstall -y \
com.visualstudio.code || true

autoremove -y

rm -f /etc/apt/sources.list.d/vscode.list
rm -f /etc/apt/sources.list.d/code.list

rm -f /etc/apt/keyrings/packages.microsoft.gpg
rm -f /usr/share/keyrings/packages.microsoft.gpg

sudo apt clean

echo ""
echo "=============================="
echo "INSTALANDO VS CODE LIMPO"
echo "=============================="

wget -qO- https://packages.microsoft.com/keys/microsoft.asc | \
gpg --dearmor | tee \
/etc/apt/keyrings/packages.microsoft.gpg > /dev/null

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" | \
tee /etc/apt/sources.list.d/vscode.list > /dev/null

apt update

apt install -y code

echo ""
echo "=============================="
echo "INSTALANDO HYPERLEDGER FIREFLY"
echo "=============================="

curl -fsSL \
https://raw.githubusercontent.com/hyperledger/firefly-cli/main/install.sh | bash

echo ""
echo "=============================="
echo "INSTALANDO WALLPAPER DO EVENTO"
echo "=============================="

mkdir -p /usr/share/backgrounds

curl -L "$WALLPAPER_URL" \
-o "/tmp/$WALLPAPER_NAME"

cp "/tmp/$WALLPAPER_NAME" \
"/usr/share/backgrounds/$WALLPAPER_NAME"

echo "Wallpaper copiado."

if id "$USUARIO_PADRAO" &>/dev/null; then
    sudo -u "$USUARIO_PADRAO" DISPLAY=:0 \
    gsettings set \
    org.cinnamon.desktop.background \
    picture-uri \
    "file:///usr/share/backgrounds/$WALLPAPER_NAME" || true

    sudo -u "$USUARIO_PADRAO" DISPLAY=:0 \
    gsettings set \
    org.cinnamon.desktop.background \
    picture-uri-dark \
    "file:///usr/share/backgrounds/$WALLPAPER_NAME" || true
fi

echo ""
echo "=============================="
echo "VERSÕES INSTALADAS"
echo "=============================="

echo "Node:"
node -v

echo ""
echo "NPM:"
npm -v

echo ""
echo "TypeScript:"
tsc -v

echo ""
echo "Docker:"
docker --version

echo ""
echo "Docker Compose:"
docker compose version

echo ""
echo "VS Code:"
code --version | head -n 1

echo ""
echo "FireFly CLI:"
ff --version || true

echo ""
echo "=============================="
echo "INSTALAÇÃO CONCLUÍDA!"
echo "=============================="

echo ""
echo "Usuário criado: $USUARIO_PADRAO"
echo ""
echo "REINICIE A SESSÃO para Docker funcionar sem sudo."
