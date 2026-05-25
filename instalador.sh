#!/bin/bash

echo "Atualizando pacotes..."
sudo apt update

echo "Removendo versões antigas do Node..."
sudo apt remove nodejs npm -y

echo "Removendo dependências antigas..."
sudo apt remove --purge nodejs libnode-dev libnode72 npm -y


echo "Limpando sistema..."
sudo apt autoremove -y
sudo apt clean

echo "Corrigindo pacotes quebrados..."
sudo apt --fix-broken install -y

echo "Instalando curl..."
sudo apt install -y curl

echo "Adicionando repositório NodeSource..."
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -

echo "Instalando Node.js 24..."
sudo apt install -y nodejs

echo ""
echo "=============================="
echo "REMOVENDO TYPESCRIPT ANTIGO"
echo "=============================="

sudo npm uninstall -g typescript || true
sudo npm cache clean --force || true

echo "Limpando sistema..."
sudo apt autoremove -y
sudo apt clean

echo "Corrigindo pacotes quebrados..."
sudo apt --fix-broken install -y

echo ""
echo "=============================="
echo "INSTALANDO TYPESCRIPT"
echo "=============================="

sudo npm install -g typescript

echo ""
echo "=============================="
echo "INSTALANDO DOCKER"
echo "=============================="

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo ${UBUNTU_CODENAME}) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo ""
echo "Adicionando usuário ao grupo docker..."

sudo usermod -aG docker $USER

echo ""
echo "=============================="
echo "INSTALANDO DOCKER DESKTOP"
echo "=============================="

cd /tmp

wget https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb

sudo apt install -y ./docker-desktop-amd64.deb

echo ""
echo "=============================="
echo "REMOVENDO VS CODE ANTIGO"
echo "=============================="

# Remove versões instaladas
sudo apt remove --purge -y code code-insiders

# Remove dependências órfãs
sudo apt autoremove -y

# Remove listas de repositório antigas
sudo rm -f /etc/apt/sources.list.d/vscode.list
sudo rm -f /etc/apt/sources.list.d/code.list

# Remove chave GPG antiga
sudo rm -f /etc/apt/keyrings/packages.microsoft.gpg
sudo rm -f /usr/share/keyrings/packages.microsoft.gpg

# Limpa cache do apt
sudo apt clean

echo ""
echo "=============================="
echo "INSTALANDO VS CODE LIMPO"
echo "=============================="

# Baixa chave oficial
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | \
gpg --dearmor | sudo tee /etc/apt/keyrings/packages.microsoft.gpg > /dev/null

# Adiciona repositório oficial
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" | \
sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

# Atualiza repositórios
sudo apt update

# Instala VSCode
sudo apt install -y code


echo ""
echo "=============================="
echo "INSTALANDO HYPERLEDGER FIREFLY"
echo "=============================="

curl -fsSL https://raw.githubusercontent.com/hyperledger/firefly-cli/main/install.sh | bash


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
echo "REINICIE A SESSÃO para o Docker funcionar sem sudo."
