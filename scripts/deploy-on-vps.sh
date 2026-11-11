#!/bin/bash
# ========================================================
# Script Otomatis Deploy TaskRumah di VPS
# Jalankan di Web Console VPS (sebagai root / sudo):
#   bash /opt/taskrumah/scripts/deploy-on-vps.sh
# Atau sekali jalan via curl:
#   curl -sSL https://raw.githubusercontent.com/andyaloys/taskrumah/main/scripts/deploy-on-vps.sh | sudo bash
# ========================================================

set -e

echo "🚀 [1/6] Memulai Setup & Deploy TaskRumah..."

# 1. Update package & install Git + Curl
echo "📦 [2/6] Memeriksa dependensi (Git, Curl)..."
apt-get update -y
apt-get install -y git curl ufw

# 2. Install Docker jika belum ada
if ! command -v docker &> /dev/null; then
    echo "🐳 Memasang Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
else
    echo "✅ Docker sudah terpasang."
fi

# 3. Install Docker Compose plugin
if ! docker compose version &> /dev/null; then
    echo "🐳 Memasang Docker Compose Plugin..."
    apt-get install -y docker-compose-plugin
else
    echo "✅ Docker Compose Plugin sudah terpasang."
fi

# 4. Setup SSH Port 2222 sebagai alternatif (antisipasi jika ISP lokal memblokir port 22)
echo "🔑 Mengatur SSH backup port (2222)..."
if ! grep -q "Port 2222" /etc/ssh/sshd_config 2>/dev/null; then
    echo "Port 22" >> /etc/ssh/sshd_config
    echo "Port 2222" >> /etc/ssh/sshd_config
    systemctl restart ssh || systemctl restart sshd || true
fi

# Buka firewall
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp || true
    ufw allow 2222/tcp || true
    ufw allow 80/tcp || true
    ufw --force enable || true
fi

# 5. Siapkan repo di /opt/taskrumah
echo "📂 [3/6] Mengunduh kode terbaru ke /opt/taskrumah..."
if [ -d "/opt/taskrumah/.git" ]; then
    cd /opt/taskrumah
    git fetch --all
    git reset --hard origin/main
else
    mkdir -p /opt/taskrumah
    git clone https://github.com/andyaloys/taskrumah.git /opt/taskrumah
    cd /opt/taskrumah
fi

# 6. Siapkan .env jika belum ada
echo "⚙️ [4/6] Mengonfigurasi environment .env..."
if [ ! -f .env ]; then
    DB_PASS="TR_$(openssl rand -hex 12)"
    JWT_SECRET="TaskRumah_Secret_Key_$(openssl rand -hex 24)"
    cat <<EOF > .env
DB_PASSWORD=$DB_PASS
JWT_KEY=$JWT_SECRET
DB_NAME=taskrumah
DB_USER=taskrumah_user
EOF
    chmod 600 .env
    echo "✅ .env berhasil dibuat."
else
    echo "✅ .env sudah ada."
fi

# 7. Build dan jalankan container
echo "🏗️ [5/6] Membangun dan menjalankan Docker containers (PostgreSQL, .NET API, Angular Web, Nginx)..."
docker compose -f docker-compose.prod.yml down --remove-orphans || true
docker compose -f docker-compose.prod.yml up -d --build

# 8. Verifikasi
echo "⏳ [6/6] Menunggu service aktif..."
sleep 10
docker ps

PUB_IP=$(curl -s ifconfig.me || echo "43.157.208.95")
echo ""
echo "========================================================"
echo "🎉 DEPLOY BERHASIL!"
echo "========================================================"
echo "🌐 Buka aplikasi di browser: http://${PUB_IP}"
echo "🔑 Login Admin default:"
echo "   Email    : ayah@taskrumah.com atau ibu@taskrumah.com"
echo "   Password : Ayah@123 atau Ibu@123"
echo "========================================================"
