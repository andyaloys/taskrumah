#!/bin/bash
# Script setup awal VPS TaskRumah
# Jalankan sebagai root: bash setup-vps.sh

set -e

echo "=== Setup VPS TaskRumah ==="

# Install Docker
if ! command -v docker &> /dev/null; then
    echo ">> Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
else
    echo ">> Docker sudah terinstall"
fi

# Install Docker Compose plugin
if ! docker compose version &> /dev/null; then
    echo ">> Installing Docker Compose..."
    apt-get update && apt-get install -y docker-compose-plugin
fi

# Buat direktori app
mkdir -p /opt/taskrumah
cd /opt/taskrumah

# Buat .env file
if [ ! -f .env ]; then
    echo ">> Membuat file .env..."
    read -p "Masukkan DB_PASSWORD: " DB_PASSWORD
    read -p "Masukkan JWT_KEY (min 32 karakter): " JWT_KEY
    echo "DB_PASSWORD=$DB_PASSWORD" > .env
    echo "JWT_KEY=$JWT_KEY" >> .env
    chmod 600 .env
    echo ">> .env dibuat"
fi

# Buka firewall port 80 dan 22
if command -v ufw &> /dev/null; then
    ufw allow 22
    ufw allow 80
    ufw --force enable
    echo ">> Firewall dikonfigurasi"
fi

echo ""
echo "=== Setup selesai! ==="
echo "Direktori app: /opt/taskrumah"
echo "Sekarang tambahkan GitHub Secrets berikut di repo andyaloys/taskrumah:"
echo ""
echo "  VPS_HOST = $(curl -s ifconfig.me)"
echo "  VPS_USER = root"
echo "  VPS_PORT = 22"
echo "  VPS_SSH_KEY = (isi dengan private key SSH)"
echo "  DB_PASSWORD = (sama dengan yang tadi diinput)"
echo "  JWT_KEY = (sama dengan yang tadi diinput)"
echo ""
echo "Untuk generate SSH key:"
echo "  ssh-keygen -t ed25519 -C 'github-actions-taskrumah' -f ~/.ssh/taskrumah_deploy"
echo "  cat ~/.ssh/taskrumah_deploy.pub >> ~/.ssh/authorized_keys"
echo "  cat ~/.ssh/taskrumah_deploy  # <-- ini yang di-paste ke VPS_SSH_KEY"
