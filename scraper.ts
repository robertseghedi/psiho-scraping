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

        // Găsește toate rândurile din tabel care conțin CUI
        $('tr').each((_, element) => {
            const secondColumn = $(element).find('td:nth-child(2)');
            const text = secondColumn.text().trim();
            const cuiMatch = text.match(/\d{6,}/); // Caută numere de 6+ cifre (CUI)
            if (cuiMatch) {
                cuis.push(cuiMatch[0]);
            }
        });

        return cuis;
    } catch (error) {
        console.error(`Eroare la pagina ${pageNumber}:`, error);
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
        console.error(`❌ Eroare la procesarea CUI ${cui}:`, error);
        return false;
    }
}

async function main() {
    const startPage = 1;
    const endPage = 72; // sau câte pagini doriți să procesați
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

        // Procesează CUI-urile găsite
        for (const cui of cuis) {
            const success = await processCUI(cui);
            if (success) {
                results.success++;
            } else {
                results.failed++;
            }
            // Așteaptă 1 secundă între request-uri pentru a nu supraîncărca API-ul
            await sleep(1000);
        }

        // Așteaptă 2 secunde între pagini
        await sleep(2000);
    }

    console.log('\n📊 Rezultate finale:');
    console.log(`Total CUI-uri găsite: ${results.cuis.length}`);
    console.log(`Procesate cu succes: ${results.success}`);
    console.log(`Eșuate: ${results.failed}`);
}

// Pornește scriptul
main().catch(console.error); 