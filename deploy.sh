#!/bin/bash

# Oprește toate procesele existente
pm2 delete all

# Curăță tot
pm2 kill

# Așteaptă puțin să se oprească tot
sleep 2

# Pornește doar un singur proces
pm2 start scraper.js \
    --name "scraper" \
    --time \
    --no-autorestart false

# Salvează configurația
pm2 save --force

echo "Gata! Verifică cu: pm2 list" 