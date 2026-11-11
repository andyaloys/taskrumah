#!/bin/bash
# ========================================================
# Auto-Deploy & Fix TaskRumah di VPS
# ========================================================
set -e

echo "🚀 [1/3] Memperbarui kode TaskRumah ke versi terbaru..."
cd /opt/taskrumah
git fetch --all
git reset --hard origin/main

echo "🏗️ [2/3] Membangun ulang container (Frontend + API + DB)..."
docker compose -f docker-compose.prod.yml up -d --build

echo "🔄 [3/3] Memasang Auto-Deploy otomatis (sync GitHub tiap 1 menit)..."
cat << 'EOF' > /opt/taskrumah/autodeploy.sh
#!/bin/bash
cd /opt/taskrumah
git fetch origin main -q
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)
if [ "$LOCAL" != "$REMOTE" ]; then
    echo "$(date): Perubahan baru terdeteksi di GitHub! Memulai auto-deploy..." >> /var/log/taskrumah-deploy.log
    git reset --hard origin/main >> /var/log/taskrumah-deploy.log 2>&1
    docker compose -f docker-compose.prod.yml up -d --build >> /var/log/taskrumah-deploy.log 2>&1
    docker image prune -f >> /var/log/taskrumah-deploy.log 2>&1
    echo "$(date): Selesai update!" >> /var/log/taskrumah-deploy.log
fi
EOF

chmod +x /opt/taskrumah/autodeploy.sh

# Pasang di crontab root agar jalan otomatis tiap 1 menit
(crontab -l 2>/dev/null | grep -v "autodeploy.sh" ; echo "* * * * * /bin/bash /opt/taskrumah/autodeploy.sh") | crontab -

echo ""
echo "=========================================================="
echo "🎉 SEMPURNA! TaskRumah sudah berhasil diperbarui & live!"
echo "🔄 Fitur Auto-Deploy VPS SUDAH AKTIF!"
echo "   Mulai sekarang, setiap Anda git push ke GitHub,"
echo "   VPS akan otomatis update sendiri dalam 1 menit"
echo "   tanpa perlu setting apapun lagi di GitHub!"
echo "🌐 Buka browser Anda: http://43.157.208.95"
echo "=========================================================="
