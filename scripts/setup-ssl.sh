#!/bin/bash
# ========================================================
# Script Setup Let's Encrypt SSL untuk familytask.web.id
# ========================================================
set -e

DOMAIN="familytask.web.id"
EMAIL="admin@familytask.web.id"

echo "🔒 [1/5] Memeriksa & memasang Certbot..."
apt-get update -y
apt-get install -y certbot ufw

# Buka port 443 di UFW
echo "🛡️ [2/5] Membuka port 443 (HTTPS) di firewall..."
ufw allow 443/tcp || true

# Stop Nginx sementara agar port 80 bebas untuk verifikasi Certbot Standalone
echo "⏸️ [3/5] Menghentikan Nginx sementara untuk verifikasi SSL..."
cd /opt/taskrumah
docker compose -f docker-compose.prod.yml stop nginx || true

# Request sertifikat dari Let's Encrypt
echo "📜 [4/5] Mengunduh sertifikat SSL gratis dari Let's Encrypt..."
certbot certonly --standalone \
    -d "$DOMAIN" \
    --non-interactive \
    --agree-tos \
    -m "$EMAIL" \
    --preferred-challenges http

# Pastikan sertifikat terpasang
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "❌ Gagal mengunduh sertifikat SSL. Mengembalikan Nginx..."
    docker compose -f docker-compose.prod.yml start nginx
    exit 1
fi

echo "✅ Sertifikat SSL berhasil didapatkan!"

# Update konfigurasi Nginx dan Docker Compose
echo "⚙️ [5/5] Mengaktifkan HTTPS di Nginx & Docker Compose..."
git pull origin main || true

docker compose -f docker-compose.prod.yml down --remove-orphans || true
docker compose -f docker-compose.prod.yml up -d

echo ""
echo "=========================================================="
echo "🎉 HTTPS AKTIF 100%!"
echo "🌐 Buka website Anda dengan aman:"
echo "   👉 https://$DOMAIN"
echo "=========================================================="
