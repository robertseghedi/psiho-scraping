#!/bin/bash

echo "🔄 Pornire proces deployment..."

# Oprește și curăță toate procesele PM2
echo "🧹 Curățare procese vechi..."
pm2 delete all
pm2 kill

# Șterge fișierele PM2 existente pentru a începe proaspăt
echo "🗑️ Ștergere fișiere PM2 vechi..."
rm -rf ~/.pm2
rm -rf /root/.pm2

# Reinițializează PM2
echo "🔄 Reinițializare PM2..."
pm2 update

# Instalează dependențele
echo "📦 Instalare dependențe..."
npm install

# Setează permisiunile corecte
echo "🔒 Setare permisiuni..."
mkdir -p ~/.pm2
sudo chown -R ubuntu:ubuntu ~/.pm2
sudo chmod -R 777 ~/.pm2
sudo chown -R ubuntu:ubuntu .

# Pornește daemon-ul PM2
echo "🚀 Pornire daemon PM2..."
pm2 status

# Pornește aplicația
echo "🚀 Pornire aplicație..."
pm2 start scraper.js \
    --name "scraper" \
    --exp-backoff-restart-delay=1000 \
    --max-memory-restart 2G \
    --merge-logs \
    --log-date-format "YYYY-MM-DD HH:mm:ss" \
    --time \
    --no-autorestart false

# Salvează configurația
echo "💾 Salvare configurație PM2..."
pm2 save --force

# Verifică dacă procesul rulează
echo "✅ Verificare status..."
pm2 list

# Așteaptă puțin să se stabilizeze
sleep 5

# Verifică din nou statusul
echo "📊 Status final:"
pm2 list

echo "✨ Deployment complet!"
echo "Pentru a monitoriza, folosește: pm2 monit"
echo "Pentru a vedea log-urile: pm2 logs scraper" 