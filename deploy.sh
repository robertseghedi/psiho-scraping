#!/bin/bash

echo "🚀 Începe procesul de deployment..."

# Actualizează sistemul
echo "📦 Actualizare sistem..."
sudo apt-get update
sudo apt-get upgrade -y

# Instalează Node.js dacă nu există
if ! command -v node &> /dev/null; then
    echo "📥 Instalare Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Instalează PM2 global dacă nu există
if ! command -v pm2 &> /dev/null; then
    echo "📥 Instalare PM2..."
    sudo npm install -g pm2
fi

# Creează directorul proiectului dacă nu există
PROJECT_DIR="/home/ubuntu/psiho-scraping"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "📁 Creare director proiect..."
    mkdir -p $PROJECT_DIR
fi

# Navigare în directorul proiectului
cd $PROJECT_DIR

# Creează package.json
echo "📝 Creare package.json..."
cat > package.json << 'EOL'
{
  "name": "psiho-scraping",
  "version": "1.0.0",
  "main": "scraper.ts",
  "scripts": {
    "start": "ts-node scraper.ts",
    "build": "tsc",
    "pm2": "ts-node scraper.ts"
  },
  "dependencies": {
    "axios": "^1.6.7",
    "cheerio": "^1.0.0-rc.12",
    "ts-node": "^10.9.2",
    "typescript": "^5.3.3"
  },
  "devDependencies": {
    "@types/node": "^20.11.19",
    "@types/cheerio": "^0.22.35"
  }
}
EOL

# Creează ecosystem.config.js
echo "📝 Creare ecosystem.config.js..."
cat > ecosystem.config.js << 'EOL'
module.exports = {
  apps: [{
    name: "scraper",
    script: "./scraper.js",
    watch: false,
    instances: 1,
    autorestart: true,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: "production"
    }
  }]
}
EOL

# Creează scraper.ts
echo "📝 Creare scraper.ts..."
cat > scraper.ts << 'EOL'
import axios from 'axios';
import * as cheerio from 'cheerio';

const BEARER_TOKEN = 'dynamic-token';
const BASE_URL = 'https://www.firme.info/medicina/psihologie/pagina_lista_firme_{PAGE}.html';
const API_URL = 'https://api.e-cui.ro/v1/companies/';

interface ScrapingResult {
    success: number;
    failed: number;
    cuis: string[];
}

async function sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function scrapePage(pageNumber: number): Promise<string[]> {
    try {
        const url = BASE_URL.replace('{PAGE}', pageNumber.toString());
        const response = await axios.get(url);
        const $ = cheerio.load(response.data);
        const cuis: string[] = [];

        $('tr').each((_, element) => {
            const secondColumn = $(element).find('td:nth-child(2)');
            const text = secondColumn.text().trim();
            const cuiMatch = text.match(/\d{6,}/);
            if (cuiMatch) {
                cuis.push(cuiMatch[0]);
            }
        });

        return cuis;
    } catch (error) {
        console.error(`Eroare la pagina ${pageNumber}:`, error.message);
        return [];
    }
}

async function processCUI(cui: string): Promise<boolean> {
    try {
        await axios.get(`${API_URL}${cui}`, {
            headers: {
                'Authorization': `Bearer ${BEARER_TOKEN}`
            }
        });
        console.log(`✅ CUI procesat cu succes: ${cui}`);
        return true;
    } catch (error) {
        console.error(`❌ Eroare la procesarea CUI ${cui}:`, error.message);
        return false;
    }
}

async function main() {
    const startPage = 1;
    const endPage = 72;
    const results: ScrapingResult = {
        success: 0,
        failed: 0,
        cuis: []
    };

    console.log('🚀 Începe procesul de scraping...');

    for (let page = startPage; page <= endPage; page++) {
        console.log(`\n📄 Procesare pagina ${page}...`);
        const cuis = await scrapePage(page);
        results.cuis.push(...cuis);

        for (const cui of cuis) {
            const success = await processCUI(cui);
            if (success) {
                results.success++;
            } else {
                results.failed++;
            }
            await sleep(1000);
        }

        await sleep(2000);
    }

    console.log('\n📊 Rezultate finale:');
    console.log(`Total CUI-uri găsite: ${results.cuis.length}`);
    console.log(`Procesate cu succes: ${results.success}`);
    console.log(`Eșuate: ${results.failed}`);
}

main().catch(console.error);
EOL

# Instalează dependințele
echo "📦 Instalare dependințe..."
npm install

# Compilează TypeScript
echo "🔨 Compilare TypeScript..."
npx tsc scraper.ts --esModuleInterop true

# Verifică dacă fișierul JS a fost creat
if [ ! -f "scraper.js" ]; then
    echo "❌ Eroare: Fișierul scraper.js nu a fost creat!"
    exit 1
fi

# Oprește orice instanță anterioară și curăță PM2
echo "🧹 Curățare PM2..."
pm2 delete all
pm2 kill

# Pornește aplicația cu PM2
echo "🚀 Pornire aplicație cu PM2..."
pm2 start ecosystem.config.js
pm2 save

# Afișează status-ul
echo "📊 Status PM2:"
pm2 list

echo "✅ Deployment complet! Pentru a vedea log-urile, rulați: pm2 logs scraper"

# Setează permisiunile corecte
chmod +x deploy.sh 