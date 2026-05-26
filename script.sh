#!/bin/bash

set -e
set -o pipefail

echo "========================================"
echo "ATUALIZANDO REPOSITÓRIOS"
echo "========================================"

sudo apt update

echo ""
echo "========================================"
echo "REMOVENDO NODE ANTIGO"
echo "========================================"

echo "VERIFICANDO NVM..."

# Detecta NVM instalado
if [ -d "$HOME/.nvm" ]; then
    echo "NVM detectado em ~/.nvm"

    export NVM_DIR="$HOME/.nvm"

    # Carrega NVM
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Remove versões instaladas pelo NVM
    if command -v nvm >/dev/null 2>&1; then

        echo "Removendo versões Node instaladas via NVM..."

        nvm deactivate 2>/dev/null || true

        # Lista versões instaladas
        INSTALLED_VERSIONS=$(nvm ls --no-colors | grep "v" | awk '{print $1}' | sed 's/->//')

        for version in $INSTALLED_VERSIONS; do
            if [[ "$version" == v* ]]; then
                echo "Removendo $version"
                nvm uninstall "$version" || true
            fi
        done

        echo "Removendo aliases do NVM..."
        rm -rf "$NVM_DIR/alias"

        echo "NVM limpo."
    fi
fi

echo "REMOVENDO NVM..."

if [ -d "$HOME/.nvm" ]; then
    rm -rf "$HOME/.nvm"
fi

# Remove entradas do shell
sed -i '/NVM_DIR/d' ~/.bashrc 2>/dev/null || true
sed -i '/nvm.sh/d' ~/.bashrc 2>/dev/null || true
sed -i '/bash_completion/d' ~/.bashrc 2>/dev/null || true

sed -i '/NVM_DIR/d' ~/.zshrc 2>/dev/null || true
sed -i '/nvm.sh/d' ~/.zshrc 2>/dev/null || true
sed -i '/bash_completion/d' ~/.zshrc 2>/dev/null || true

# Remove apenas se estiver instalado
if dpkg -l | grep -q nodejs; then
    sudo apt remove -y nodejs
fi

if dpkg -l | grep -q npm; then
    sudo apt remove -y npm
fi

for pkg in nodejs libnode-dev libnode72 npm; do
    if dpkg -l | grep -q "^ii  $pkg "; then
        sudo apt remove --purge -y "$pkg"
    fi
done

echo "REMOVENDO TYPESCRIPT ANTIGO..."

# Verifica se npm existe antes
if command -v npm >/dev/null 2>&1; then
    sudo npm uninstall -g typescript ts-node || true
fi

# Remove diretórios apenas se existirem
[ -d /usr/lib/node_modules/typescript ] && sudo rm -rf /usr/lib/node_modules/typescript
[ -d /usr/lib/node_modules/ts-node ] && sudo rm -rf /usr/lib/node_modules/ts-node
[ -d ~/.npm ] && sudo rm -rf ~/.npm
[ -d ~/.cache/npm ] && sudo rm -rf ~/.cache/npm

echo ""
echo "========================================"
echo "LIMPANDO SISTEMA"
echo "========================================"

sudo apt autoremove -y
sudo apt clean

echo ""
echo "========================================"
echo "CORRIGINDO PACOTES"
echo "========================================"

sudo apt --fix-broken install -y

echo ""
echo "========================================"
echo "REMOVENDO DOCKER ANTIGO (SEGURO)"
echo "========================================"

# 1. Parar serviços
sudo systemctl stop docker || true
sudo systemctl stop docker.socket || true

# 2. Matar processos presos (IMPORTANTE)
sudo killall dockerd containerd 2>/dev/null || true

# 3. Remover containers via CLI (se ainda existir docker)
if command -v docker >/dev/null 2>&1; then
    echo "Limpando containers..."
    docker ps -aq | xargs -r docker rm -f || true
    docker system prune -af --volumes || true
fi

# 4. Desmontar overlay (ESSENCIAL para evitar 'busy')
echo "Desmontando volumes Docker..."
mount | grep docker | awk '{print $3}' | xargs -r sudo umount -l || true

# 5. Remover pacotes
for pkg in \
docker-desktop \
docker-ce \
docker-ce-cli \
docker-buildx-plugin \
docker-compose-plugin \
docker-ce-rootless-extras \
containerd.io \
docker.io
do
    dpkg -l | grep -q "^ii  $pkg " && sudo apt purge -y "$pkg" || true
done

echo ""
echo "========================================"
echo "LIMPANDO DADOS DO DOCKER (SEGURAMENTE)"
echo "========================================"

sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf ~/.docker
sudo rm -rf /usr/local/lib/docker
sudo rm -rf /opt/docker-desktop

echo ""
echo "========================================"
echo "REMOVENDO FIREFLY ANTIGO"
echo "========================================"

# Só executa se docker existir
if command -v docker >/dev/null 2>&1; then
    docker rm -f $(docker ps -aq) 2>/dev/null || true
    docker volume prune -af 2>/dev/null || true
    docker network prune -f 2>/dev/null || true
    docker system prune -af 2>/dev/null || true
fi

[ -d ~/.firefly ] && rm -rf ~/.firefly
[ -d ~/firefly ] && rm -rf ~/firefly
[ -d ~/.docker/cli-plugins/firefly-cli ] && rm -rf ~/.docker/cli-plugins/firefly-cli

[ -f /usr/local/bin/ff ] && sudo rm -f /usr/local/bin/ff

echo ""
echo "========================================"
echo "REMOVENDO REPOSITÓRIOS ANTIGOS"
echo "========================================"

[ -f /etc/apt/sources.list.d/docker.list ] && \
sudo rm -f /etc/apt/sources.list.d/docker.list

[ -f /etc/apt/keyrings/docker.asc ] && \
sudo rm -f /etc/apt/keyrings/docker.asc

[ -f /usr/share/keyrings/docker-archive-keyring.gpg ] && \
sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg

sudo apt autoremove -y --purge

echo ""
echo "========================================"
echo "INSTALANDO DEPENDÊNCIAS"
echo "========================================"

sudo apt install -y \
curl \
wget \
git \
ca-certificates \
gnupg \
lsb-release \
build-essential

echo ""
echo "========================================"
echo "INSTALANDO NODE.JS 24"
echo "========================================"

curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -

sudo apt install -y nodejs

echo ""
echo "========================================"
echo "INSTALANDO TYPESCRIPT"
echo "========================================"

sudo npm install -g \
typescript \
ts-node \
@types/node

echo ""
echo "========================================"
echo "INSTALANDO DOCKER"
echo "========================================"

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo $UBUNTU_CODENAME) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

sudo apt install -y \
docker-ce \
docker-ce-cli \
containerd.io \
docker-buildx-plugin \
docker-compose-plugin

echo ""
echo "========================================"
echo "INICIANDO DOCKER"
echo "========================================"

sudo systemctl enable docker
sudo systemctl start docker

echo ""
echo "========================================"
echo "ADICIONANDO USUÁRIO AO GRUPO DOCKER"
echo "========================================"

sudo usermod -aG docker $USER

echo ""
echo "========================================"
echo "INSTALANDO HYPERLEDGER FIREFLY"
echo "========================================"

cd /tmp

wget https://github.com/hyperledger/firefly-cli/releases/download/v1.4.0/firefly-cli_1.4.0_Linux_x86_64.tar.gz

tar -xvf firefly-cli_1.4.0_Linux_x86_64.tar.gz

chmod +x ff

sudo mv ff /usr/local/bin/

echo ""
echo "========================================"
echo "CRIANDO AMBIENTE FIREFLY DEV"
echo "========================================"

ff init dev

echo ""
echo "========================================"
echo "VERSÕES INSTALADAS"
echo "========================================"

echo ""
echo "NODE:"
node -v

echo ""
echo "NPM:"
npm -v

echo ""
echo "TYPESCRIPT:"
tsc -v

echo ""
echo "TS-NODE:"
ts-node -v

echo ""
echo "DOCKER:"
docker --version

echo ""
echo "DOCKER COMPOSE:"
docker compose version

echo ""
echo "FIREFLY:"
ff version

echo ""
echo "========================================"
echo "TESTANDO DOCKER"
echo "========================================"

sudo docker run hello-world

echo ""
echo "========================================"
echo "INSTALAÇÃO FINALIZADA"
echo "========================================"

