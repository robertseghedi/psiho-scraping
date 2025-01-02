#!/bin/bash

# Oprește procesul anterior dacă există
pm2 stop all || true
pm2 delete all || true
pm2 kill || true

# Actualizează codul
git pull origin main

# Instalează dependențele
npm install

# Asigură-ne că avem permisiunile corecte
sudo chown -R ubuntu:ubuntu ~/.pm2
sudo chown -R ubuntu:ubuntu .

# Pornește PM2 daemon dacă nu rulează
pm2 ping || pm2 resurrect

# Pornește aplicația folosind ecosystem file
pm2 start ecosystem.config.cjs

# Salvează configurația
pm2 save --force

# Afișează status
pm2 list

echo "Procesul ar trebui să ruleze acum. Pentru a verifica:"
echo "pm2 list        # vezi statusul"
echo "pm2 logs        # vezi log-urile"
echo "pm2 monit      # monitorizează procesul" 