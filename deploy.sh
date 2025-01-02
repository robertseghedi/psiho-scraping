#!/bin/bash

echo "🚀 Începe procesul de deployment..."

# Verifică dacă suntem în directorul corect
if [ ! -f "scraper.ts" ]; then
    echo "❌ Eroare: Nu s-a găsit scraper.ts în directorul curent!"
    exit 1
fi

# Instalează dependințele dacă nu există
if [ ! -d "node_modules" ]; then
    echo "📦 Instalare dependințe..."
    npm install
fi

# Oprește orice instanță anterioară și curăță PM2
echo "🧹 Curățare PM2..."
pm2 delete all
pm2 kill

# Compilează TypeScript
echo "🔨 Compilare TypeScript..."
npx tsc scraper.ts --esModuleInterop true

# Verifică dacă compilarea a reușit
if [ ! -f "scraper.js" ]; then
    echo "❌ Eroare: Compilarea TypeScript a eșuat!"
    exit 1
fi

# Pornește aplicația cu PM2
echo "🚀 Pornire aplicație cu PM2..."
pm2 start ecosystem.config.js
pm2 save

# Afișează status-ul
echo "📊 Status PM2:"
pm2 list

echo "✅ Deployment complet! Pentru a vedea log-urile, rulați: pm2 logs scraper" 