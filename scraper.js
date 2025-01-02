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
        const response = await axios.get(url);
        const $ = cheerio.load(response.data);
        const cuis = [];

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

async function processCUI(cui) {
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
    const results = {
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