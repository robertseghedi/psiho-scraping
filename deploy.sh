#!/bin/bash

echo "🚀 Începe procesul de deployment..."

# Verifică dacă suntem în directorul corect
if [ ! -f "scraper.ts" ]; then
    echo "❌ Eroare: Nu s-a găsit scraper.ts în directorul curent!"
    exit 1
fi

# Curăță PM2
echo "🧹 Curățare PM2..."
pm2 delete all
pm2 kill

# Verifică și instalează dependențele
echo "📦 Verificare dependențe..."
npm install

# Pornește aplicația direct cu ts-node prin PM2
echo "🚀 Pornire aplicație..."
pm2 start ecosystem.config.js --time

# Salvează configurația PM2
echo "💾 Salvare configurație PM2..."
pm2 save

# Afișează status-ul și log-urile imediat
echo "📊 Status PM2:"
pm2 list
echo "📜 Log-uri recente:"
pm2 logs --lines 20 --nostream 