import axios from 'axios';
import * as cheerio from 'cheerio';

const BEARER_TOKEN = 'dynamic-token';
const BASE_URL = 'https://www.firme.info/medicina/psihologie/pagina_lista_firme_{PAGE}.html';
const API_URL = 'https://api.e-cui.ro/v1/companies/';

async function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function scrapePage(pageNumber) {
    try {
        const url = BASE_URL.replace('{PAGE}', pageNumber.toString());
        console.log(`🔍 Accesare URL: ${url}`);
        
        const response = await axios.get(url);
        const $ = cheerio.load(response.data);
        const cuis = [];

        // Selectăm toate rândurile din tbody
        $('table.table-striped tbody tr').each((_, element) => {
            // CUI-ul este în al doilea td din fiecare tr
            const cuiCell = $(element).find('td:nth-child(2)');
            const cui = cuiCell.text().trim();
            
            // Verificăm dacă e un CUI valid (doar cifre)
            if (cui && /^\d+$/.test(cui)) {
                console.log(`🔎 CUI găsit: ${cui}`);
                cuis.push(cui);
            }
        });

        console.log(`📊 Total CUI-uri găsite pe pagina ${pageNumber}: ${cuis.length}`);
        return cuis;
    } catch (error) {
        console.error(`❌ Eroare la pagina ${pageNumber}:`, error.message);
        return [];
    }
}

async function processCUI(cui) {
    try {
        // Adăugăm un delay între requesturi pentru a evita rate limiting
        await sleep(2000);

        const response = await axios.get(`${API_URL}${cui}`, {
            headers: {
                'Authorization': `Bearer ${BEARER_TOKEN}`,
                'Accept': 'application/json'
            },
            validateStatus: function (status) {
                return status < 600; // Acceptă orice status pentru a evita crash-ul
            }
        });

        if (response.status === 500) {
            console.log(`⚠️ CUI ${cui} nu a fost găsit în baza de date`);
            return false;
        }

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
    const results = {
        success: 0,
        failed: 0,
        cuis: []
    };

    console.log('🚀 Începe procesul de scraping...\n');

    for (let page = startPage; page <= endPage; page++) {
        console.log(`\n📄 Procesare pagina ${page}...`);
        const cuis = await scrapePage(page);
        
        if (cuis.length === 0) {
            console.log(`⚠️ Nu s-au găsit CUI-uri pe pagina ${page}`);
            continue;
        }

        results.cuis.push(...cuis);

        for (const cui of cuis) {
            const success = await processCUI(cui);
            if (success) {
                results.success++;
            } else {
                results.failed++;
            }
        }

        console.log(`\n✨ Pagina ${page} completă. Progres: ${results.success + results.failed}/${results.cuis.length}`);
        await sleep(2000);
    }

    console.log('\n📊 Rezultate finale:');
    console.log(`Total CUI-uri găsite: ${results.cuis.length}`);
    console.log(`Procesate cu succes: ${results.success}`);
    console.log(`Eșuate: ${results.failed}`);
}

main().catch(console.error); 