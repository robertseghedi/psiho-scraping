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
    --watch \
    --restart-delay=3000 \
    --no-autorestart=false \
    --time

# Forțează salvarea configurației PM2
pm2 save --force

# Afișează logs
pm2 logs scraper 