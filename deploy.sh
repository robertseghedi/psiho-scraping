#!/bin/bash

# Oprește procesul anterior dacă există
pm2 stop scraper || true
pm2 delete scraper || true

# Actualizează codul
git pull origin main

# Instalează dependențele
npm install

# Compilează TypeScript
npx tsc --target es2020 --module es2020 --moduleResolution node --outDir dist scraper.ts

# Asigură-ne că PM2 rulează în mod daemon
pm2 status > /dev/null || pm2 start

# Pornește procesul cu PM2
pm2 start dist/scraper.js \
    --name "scraper" \
    --max-memory-restart 2G \
    --node-args="--max-old-space-size=2048" \
    --exp-backoff-restart-delay=1000 \
    --time \
    --watch false \
    --instances 1 \
    --merge-logs \
    --log-date-format "YYYY-MM-DD HH:mm:ss"

# Forțează salvarea configurației PM2
pm2 save --force

# Afișează status-ul
pm2 list

# Așteaptă puțin să se stabilizeze procesul
sleep 2

echo "Procesul rulează în background. Folosește următoarele comenzi:"
echo "pm2 logs scraper    # pentru a vedea log-urile"
echo "pm2 monit          # pentru monitorizare"
echo "pm2 list           # pentru a vedea status-ul" 