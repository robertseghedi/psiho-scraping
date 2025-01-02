#!/bin/bash

# Oprește procesul anterior dacă există
pm2 stop scraper || true
pm2 delete scraper || true

# Actualizează codul
git pull origin main

# Instalează dependențele
npm install

# Compilează TypeScript cu configurația corectă pentru ES modules
npx tsc --target es2020 --module es2020 --moduleResolution node --outDir dist scraper.ts

# Pornește procesul cu PM2 (folosind fișierul din directorul dist)
pm2 start dist/scraper.js \
    --name "scraper" \
    --max-memory-restart 2G \
    --node-args="--max-old-space-size=2048 --experimental-modules" \
    --exp-backoff-restart-delay=1000 \
    --time \
    -i 1 \
    --merge-logs \
    --log-date-format "YYYY-MM-DD HH:mm:ss" \
    --kill-timeout 3000 \
    --listen-timeout 8000 \
    --wait-ready \
    --no-daemon

# Detașează procesul de terminal
pm2 detach

# Forțează salvarea configurației PM2
pm2 save --force

# Afișează status-ul final
pm2 list

echo "Procesul rulează acum în background. Poți închide terminalul."
echo "Pentru a vedea log-urile folosește: pm2 logs scraper"
echo "Pentru a monitoriza folosește: pm2 monit" 