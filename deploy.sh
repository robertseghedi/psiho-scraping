#!/bin/bash
# Oprește procesul anterior dacă există
pm2 stop scraper || true
pm2 delete scraper || true

# Instalează dependențele
npm install


# Pornește procesul cu PM2
pm2 start scraper.js \
    --name "scraper" \
    --max-memory-restart 12G \
    --node-args="--max-old-space-size=12288" \
    --exp-backoff-restart-delay=1000

# Salvează configurația PM2
pm2 save

# Afișează logs
pm2 logs scraper 